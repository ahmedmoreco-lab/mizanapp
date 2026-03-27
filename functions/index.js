const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.checkInMonitor = functions.pubsub
  .schedule("every 1 hours")
  .timeZone("Africa/Cairo")
  .onRun(async (context) => {
    const now = Date.now();
    const threshold = 24 * 60 * 60 * 1000; // 24 hours

    const usersSnapshot = await admin.firestore()
      .collection("users")
      .get();

    const promises = [];

    usersSnapshot.forEach((doc) => {
      const data = doc.data();

      // ✅ Only check elders
      if (data.role !== "elder") return;

      if (!data.lastCheckIn) return;

      const lastCheck = data.lastCheckIn.toDate().getTime();
      const difference = now - lastCheck;

      // 🚨 If inactive for 24 hours
      if (difference >= threshold) {
        const contactEmail = data.trustedContactEmail;

        if (!contactEmail) {
          console.log(`⚠ No contact for user ${doc.id}`);
          return;
        }

        // 🔥 For now: just log (later email/SMS)
        console.log(
          `🚨 ALERT: User ${doc.id} missed check-in. Notify: ${contactEmail}`
        );

        // OPTIONAL: Save alert to Firestore (VERY SMART FOR DEMO)
        const alertPromise = admin.firestore()
          .collection("alerts")
          .add({
            userId: doc.id,
            contactEmail: contactEmail,
            message: "User missed check-in",
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });

        promises.push(alertPromise);
      }
    });

    await Promise.all(promises);

    return null;
  });