const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendRequestStatusNotification = functions.firestore
    .document("requests/{requestId}")
    .onUpdate(async (change, context) => {
        const newValue = change.after.data();
        const oldValue = change.before.data();

        // Check if status changed to 'assigned'
        if (newValue.status === "assigned" && oldValue.status !== "assigned") {
            const userId = newValue.userId; // The beneficiary's ID
            const volunteerName = newValue.volunteerName || "A volunteer";
            const requestId = context.params.requestId;

            try {
                // Get the beneficiary's FCM token
                const tokenSnapshot = await admin.firestore()
                    .collection("user_tokens")
                    .doc(userId)
                    .get();

                if (!tokenSnapshot.exists) {
                    console.log("No token found for user:", userId);
                    return null;
                }

                const fcmToken = tokenSnapshot.data().fcmToken;

                // Notification payload
                const payload = {
                    notification: {
                        title: "Request Accepted!",
                        body: `${volunteerName} has accepted your request and is on the way.`,
                    },
                    data: {
                        type: "request",
                        id: requestId,
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                    token: fcmToken,
                };

                // Send the notification
                const response = await admin.messaging().send(payload);
                console.log("Successfully sent message:", response);
                return response;
            } catch (error) {
                console.log("Error sending notification:", error);
                return null;
            }
        }

        return null;
    });
