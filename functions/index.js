const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendRequestStatusNotification = functions.firestore
    .document("requests/{requestId}")
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const previousData = change.before.data();

        // Check if status has changed
        if (newData.status === previousData.status) {
            return null;
        }

        const userId = newData.userId;
        const status = newData.status;
        const volunteerId = newData.volunteerId;

        // Get user's FCM token from users_tokens collection
        const tokenDoc = await admin.firestore().collection("users_tokens").doc(userId).get();

        if (!tokenDoc.exists) {
            console.log("No token document found for user", userId);
            return null;
        }

        const fcmToken = tokenDoc.data().fcmToken;

        if (!fcmToken) {
            console.log("No FCM token for user", userId);
            return null;
        }

        let title = "Request Update";
        let body = `Your request status has been updated to ${status}.`;

        if (status === "assigned" && volunteerId) {
            // Get volunteer name
            const volunteerDoc = await admin.firestore()
                .collection("users")
                .doc(volunteerId)
                .get();
            const volunteerName = volunteerDoc.data().name || "A volunteer";

            title = "Request Accepted";
            body = `${volunteerName} has accepted your request.`;
        } else if (status === "arriving") {
            title = "Volunteer Arriving";
            body = "The volunteer is on their way to your location.";
        } else if (status === "completed") {
            title = "Request Completed";
            body = "Your request has been marked as completed.";
        }

        const message = {
            notification: {
                title: title,
                body: body,
            },
            token: fcmToken,
            data: {
                requestId: context.params.requestId,
                status: status,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
        };

        try {
            // Send FCM notification
            await admin.messaging().send(message);
            console.log("Notification sent successfully");

            // Save to Firestore
            await admin.firestore()
                .collection("users")
                .doc(userId)
                .collection("notifications")
                .add({
                    title: title,
                    body: body,
                    requestId: context.params.requestId,
                    status: status,
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            console.log("Notification saved to Firestore");

        } catch (error) {
            console.error("Error sending/saving notification:", error);
        }
    });
