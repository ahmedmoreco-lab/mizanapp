// TODO: Requires Blaze plan — deploy with: firebase deploy --only functions
// All functions in this file require the Firebase Blaze (pay-as-you-go) plan.

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ─────────────────────────────────────────────────────────────────────────────
// FUNCTION 1 — SOS Alert
// Trigger: new document in users/{elderId}/sosEvents/{eventId}
// Fires the moment the Elder presses the SOS button in the app.
// Notifies ALL trusted contacts immediately (SOS bypasses escalation order).
// TODO: Requires Blaze plan
// ─────────────────────────────────────────────────────────────────────────────
exports.sosAlertTrigger = functions.firestore
  .document("users/{elderId}/sosEvents/{eventId}")
  .onCreate(async (snap, context) => {
    const { elderId, eventId } = context.params;

    // Guard: skip if already handled (prevents double-fire on retries)
    const eventData = snap.data();
    if (eventData.notificationSent) return null;

    const elderDoc = await db.collection("users").doc(elderId).get();
    if (!elderDoc.exists) {
      console.error(`SOS: Elder ${elderId} not found.`);
      return null;
    }

    const elder = elderDoc.data();
    const elderName = elder.name || elder.email || "Your elder";

    // Collect all contacts (escalation order first, fall back to flat list)
    let contactIds = elder.escalationOrder || [];
    if (contactIds.length === 0) contactIds = elder.trustedContacts || [];
    if (contactIds.length === 0 && elder.trustedContactId) {
      contactIds = [elder.trustedContactId];
    }

    if (contactIds.length === 0) {
      console.warn(`SOS: Elder ${elderId} has no contacts — cannot notify.`);
      await snap.ref.update({ notificationSent: false, resolvedAt: null });
      return null;
    }

    const sendPromises = contactIds.map((contactId) =>
      _sendSosToContact(contactId, elderId, elderName)
    );
    await Promise.all(sendPromises);

    // Mark the event as handled
    await snap.ref.update({
      notificationSent: true,
    });

    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// Helper — Send SOS push notification to a single contact
// ─────────────────────────────────────────────────────────────────────────────
async function _sendSosToContact(contactId, elderId, elderName) {
  const contactDoc = await db.collection("users").doc(contactId).get();
  if (!contactDoc.exists) {
    console.warn(`SOS: Contact ${contactId} not found — skipping.`);
    return;
  }

  const fcmToken = contactDoc.data().fcmToken;
  if (!fcmToken) {
    console.warn(`SOS: Contact ${contactId} has no FCM token — skipping push.`);
    return;
  }

  const message = {
    token: fcmToken,
    notification: {
      title: "🚨 EMERGENCY — SoulPing Care",
      body: `${elderName} has pressed the SOS button. Please check on them immediately.`,
    },
    data: {
      type: "sos",
      elderId: elderId,
      elderName: elderName,
    },
    android: {
      priority: "high",
      notification: {
        channelId: "soulping_alerts",
        sound: "default",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
    },
    apns: {
      payload: {
        aps: { sound: "default", badge: 1, contentAvailable: true },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    console.log(`✅ SOS sent to contact ${contactId} for elder ${elderId}. FCM: ${response}`);
  } catch (err) {
    console.error(`❌ SOS FCM failed for contact ${contactId}: ${err.message}`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FUNCTION 2 — Inactivity Monitor (Scheduled — every 30 minutes)
// Checks every elder's last check-in against their inactivity threshold.
// Implements escalation: notifies contacts one by one across consecutive runs.
//
// Also runs the PASSIVE BACKGROUND MONITOR check (two-stage flow):
//   1. If an elder has monitoringEnabled and no activity for > activityThreshold
//      → first send a gentle "Are you okay?" prompt to the ELDER
//   2. If the prompt was sent and there is still no activity / check-in after
//      the grace period → fall through to the contact alert.
// TODO: Requires Blaze plan
// ─────────────────────────────────────────────────────────────────────────────

// Activity gap defaults (hours). The elder's per-user inactivityThresholdHours
// is used if present, otherwise we default to 12h activity / 1h grace.
const DEFAULT_ACTIVITY_THRESHOLD_HOURS = 12;
const DEFAULT_ACTIVITY_GRACE_HOURS = 1;

exports.checkInMonitor = functions.pubsub
  .schedule("every 30 minutes")
  .timeZone("UTC")
  .onRun(async (_context) => {
    const now = Date.now();

    const usersSnapshot = await db
      .collection("users")
      .where("role", "==", "elder")
      .get();

    const promises = [];

    usersSnapshot.forEach((doc) => {
      const data = doc.data();
      // Each elder gets two independent checks:
      //   (a) passive activity-gap (only if monitoringEnabled)
      //   (b) classic missed-check-in escalation
      promises.push(_runPassiveActivityCheck(doc, now));

      if (!data.lastCheckIn) return;

      const thresholdHours = data.inactivityThresholdHours || 24;
      const thresholdMs = thresholdHours * 60 * 60 * 1000;
      const lastCheck = data.lastCheckIn.toDate().getTime();
      const differenceMs = now - lastCheck;

      if (differenceMs < thresholdMs) return; // still within threshold, skip

      // Build escalation order: prefer escalationOrder, fall back to trustedContacts
      let escalationOrder = data.escalationOrder || [];
      if (escalationOrder.length === 0) escalationOrder = data.trustedContacts || [];
      if (escalationOrder.length === 0 && data.trustedContactId) {
        escalationOrder = [data.trustedContactId];
      }

      if (escalationOrder.length === 0) {
        console.log(`⚠️  No contacts for elder ${doc.id} — skipping.`);
        return;
      }

      const currentLevel = data.currentEscalationLevel || 0;
      if (currentLevel >= escalationOrder.length) {
        console.log(`🛑  Elder ${doc.id} — all contacts exhausted for this inactivity period.`);
        return;
      }

      const contactId = escalationOrder[currentLevel];
      const elderName = data.name || data.email || "Your elder";

      promises.push(_notifyContactInactivity(doc, contactId, elderName, currentLevel + 1));
    });

    await Promise.all(promises);
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// Helper — Passive activity-gap two-stage flow
// Reads users/{elderId}/status/current to find lastActivityAt and decide
// whether to (a) prompt the elder, (b) fall through to contact alert, or
// (c) do nothing.
// ─────────────────────────────────────────────────────────────────────────────
async function _runPassiveActivityCheck(elderDoc, now) {
  try {
    const data = elderDoc.data();
    const statusRef = elderDoc.ref.collection("status").doc("current");
    const statusSnap = await statusRef.get();
    if (!statusSnap.exists) return;

    const status = statusSnap.data();
    if (status.monitoringEnabled !== true) return;
    if (!status.lastActivityAt) return;

    const lastActivityMs = status.lastActivityAt.toDate().getTime();
    const activityGapMs = now - lastActivityMs;

    const activityThresholdHours =
      data.inactivityThresholdHours || DEFAULT_ACTIVITY_THRESHOLD_HOURS;
    const activityThresholdMs = activityThresholdHours * 60 * 60 * 1000;
    if (activityGapMs < activityThresholdMs) return;

    const elderName = data.name || data.email || "Your elder";

    // CASE A — gentle prompt to the elder first
    if (status.activityCheckPromptSent !== true) {
      await _sendCheckInPromptToElder(elderDoc.id, data.fcmToken, elderName);
      await statusRef.set(
        {
          activityCheckPromptSent: true,
          activityPromptSentAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      console.log(`👋  Sent activity prompt to elder ${elderDoc.id}.`);
      return;
    }

    // CASE B — prompt was sent; check grace window before alerting contacts
    const promptSentAt = status.activityPromptSentAt
      ? status.activityPromptSentAt.toDate().getTime()
      : lastActivityMs;
    const graceMs = DEFAULT_ACTIVITY_GRACE_HOURS * 60 * 60 * 1000;
    if (now - promptSentAt < graceMs) return;

    // Anti-spam: don't re-alert if already notified recently for this period.
    if (status.notifiedAt) {
      const notifiedMs = status.notifiedAt.toDate().getTime();
      if (now - notifiedMs < graceMs) return;
    }

    let escalationOrder = data.escalationOrder || [];
    if (escalationOrder.length === 0)
      escalationOrder = data.trustedContacts || [];
    if (escalationOrder.length === 0 && data.trustedContactId) {
      escalationOrder = [data.trustedContactId];
    }
    if (escalationOrder.length === 0) {
      console.log(
        `⚠️  Activity gap on ${elderDoc.id} but no contacts — cannot escalate.`
      );
      return;
    }

    const contactId = escalationOrder[0];
    await _notifyContactInactivity(elderDoc, contactId, elderName, 1);
    await statusRef.set(
      { notifiedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
  } catch (err) {
    console.error(
      `Activity check failed for elder ${elderDoc.id}: ${err.message}`
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper — Send the gentle "Are you okay?" prompt to the elder
// ─────────────────────────────────────────────────────────────────────────────
async function _sendCheckInPromptToElder(elderId, fcmToken, elderName) {
  // In-app alert record so the dashboard / future log view can surface it.
  await db.collection("alerts").add({
    userId: elderId,
    contactId: elderId, // recipient is the elder themselves
    elderName: elderName,
    message: "We noticed no activity for a while. Please tap I'm OK.",
    type: "activity_prompt",
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false,
  });

  if (!fcmToken) {
    console.log(
      `📭  Elder ${elderId} has no FCM token — activity prompt saved only.`
    );
    return;
  }

  const message = {
    token: fcmToken,
    notification: {
      title: "👋 Are you okay?",
      body: "We noticed no activity for a while. Please open SoulPing Care and tap I'm OK.",
    },
    data: {
      type: "activity_prompt",
      elderId: elderId,
    },
    android: {
      priority: "high",
      notification: {
        channelId: "soulping_alerts",
        sound: "default",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
    },
    apns: {
      payload: {
        aps: { sound: "default", badge: 1, contentAvailable: true },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    console.log(
      `✅  Activity prompt sent to elder ${elderId}. FCM: ${response}`
    );
  } catch (err) {
    console.error(
      `❌  Activity prompt FCM failed for elder ${elderId}: ${err.message}`
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper — Notify a contact about missed check-in, advance escalation level
// ─────────────────────────────────────────────────────────────────────────────
async function _notifyContactInactivity(elderDoc, contactId, elderName, escalationLevel) {
  const contactDoc = await db.collection("users").doc(contactId).get();
  if (!contactDoc.exists) {
    console.warn(`Inactivity: Contact ${contactId} not found — skipping.`);
    return;
  }

  const contactData = contactDoc.data();
  const fcmToken = contactData.fcmToken;

  // Write alert record for in-app display regardless of FCM availability
  await db.collection("alerts").add({
    userId: elderDoc.id,
    contactId: contactId,
    elderName: elderName,
    message: `${elderName} has not checked in. Please verify they are safe.`,
    escalationLevel: escalationLevel,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false,
  });

  // Advance escalation level so next run notifies the next contact
  await elderDoc.ref.update({
    currentEscalationLevel: escalationLevel,
    lastEscalatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  if (!fcmToken) {
    console.log(`📭  Contact ${contactId} has no FCM token — alert saved to Firestore only.`);
    return;
  }

  const message = {
    token: fcmToken,
    notification: {
      title: "⚠️ Safety Alert — SoulPing Care",
      body: `${elderName} hasn't checked in for over ${elderDoc.data().inactivityThresholdHours || 24} hours. Please check on them.`,
    },
    data: {
      type: "missed_checkin",
      elderId: elderDoc.id,
      elderName: elderName,
      escalationLevel: String(escalationLevel),
    },
    android: {
      priority: "high",
      notification: {
        channelId: "soulping_alerts",
        sound: "default",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
    },
    apns: {
      payload: {
        aps: { sound: "default", badge: 1 },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    console.log(
      `✅  Escalation L${escalationLevel}: Notified contact ${contactId} for elder ${elderDoc.id}. FCM: ${response}`
    );
  } catch (err) {
    console.error(`❌  FCM send failed for contact ${contactId}: ${err.message}`);
  }
}
