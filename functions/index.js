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
// TODO: Requires Blaze plan
// ─────────────────────────────────────────────────────────────────────────────
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
