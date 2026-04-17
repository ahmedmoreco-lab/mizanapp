const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ─────────────────────────────────────────────────────────────────────────────
// MAIN CRON — Runs every hour, checks all elders for missed check-ins
// ─────────────────────────────────────────────────────────────────────────────
exports.checkInMonitor = functions.pubsub
  .schedule("every 1 hours")
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

      // Build escalation order from new list, fall back to legacy field
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
        console.log(`🛑  Elder ${doc.id} — all contacts exhausted.`);
        return;
      }

      const contactId = escalationOrder[currentLevel];
      const elderName = data.name || data.email || "Your elder";

      promises.push(_notifyContact(doc, contactId, elderName, currentLevel + 1));
    });

    await Promise.all(promises);
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// Helper — Look up contact, send push notification, write alert record
// ─────────────────────────────────────────────────────────────────────────────
async function _notifyContact(elderDoc, contactId, elderName, escalationLevel) {
  // Fetch contact's FCM token
  const contactDoc = await db.collection("users").doc(contactId).get();
  if (!contactDoc.exists) {
    console.log(`⚠️  Contact ${contactId} not found — skipping.`);
    return;
  }

  const contactData = contactDoc.data();
  const fcmToken = contactData.fcmToken;

  // Write alert to Firestore regardless (for in-app display)
  await db.collection("alerts").add({
    userId: elderDoc.id,
    contactId: contactId,
    elderName: elderName,
    message: `${elderName} has not checked in. Please verify they are safe.`,
    escalationLevel: escalationLevel,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false,
  });

  // Advance escalation level on the elder's document so next run notifies the next contact
  await elderDoc.ref.update({
    currentEscalationLevel: escalationLevel,
    lastEscalatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Send push notification if we have an FCM token
  if (!fcmToken) {
    console.log(`📭  Contact ${contactId} has no FCM token — alert saved to Firestore only.`);
    return;
  }

  const notification = {
    title: "🚨 Safety Alert — SoulPing Care",
    body: `${elderName} hasn't checked in for over ${elderDoc.data().inactivityThresholdHours || 24} hours. Please check on them.`,
  };

  const message = {
    token: fcmToken,
    notification,
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