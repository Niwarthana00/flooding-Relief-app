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

exports.sendChatNotification = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        const messageData = snapshot.data();
        const receiverId = messageData.receiverId;
        const senderId = messageData.senderId;
        const messageText = messageData.text;
        const requestId = messageData.requestId; // Optional now

        if (!receiverId || !senderId) {
            console.log("Missing receiverId or senderId");
            return null;
        }

        try {
            // Get receiver's FCM token
            const tokenDoc = await admin.firestore()
                .collection("users_tokens")
                .doc(receiverId)
                .get();

            if (!tokenDoc.exists) {
                console.log("No token document found for user", receiverId);
                return null;
            }

            const fcmToken = tokenDoc.data().fcmToken;

            if (!fcmToken) {
                console.log("No FCM token for user", receiverId);
                return null;
            }

            // Get sender's name
            const senderDoc = await admin.firestore()
                .collection("users")
                .doc(senderId)
                .get();

            const senderName = senderDoc.exists ? (senderDoc.data().name || "Someone") : "Someone";

            const payload = {
                notification: {
                    title: `New message from ${senderName}`,
                    body: messageText,
                },
                token: fcmToken,
                data: {
                    type: "chat",
                    chatId: context.params.chatId,
                    senderId: senderId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
            };

            if (requestId) {
                payload.data.requestId = requestId;
            }

            // Send FCM notification
            await admin.messaging().send(payload);
            console.log("Chat notification sent successfully");

            // Save to in-app notifications
            const notificationsRef = admin.firestore()
                .collection("users")
                .doc(receiverId)
                .collection("notifications");

            // Check for existing unread chat notification from this sender
            const existingSnapshot = await notificationsRef
                .where("type", "==", "chat")
                .where("senderId", "==", senderId)
                .where("isRead", "==", false)
                .limit(1)
                .get();

            if (!existingSnapshot.empty) {
                // Update existing notification
                const docId = existingSnapshot.docs[0].id;
                await notificationsRef.doc(docId).update({
                    title: `New messages from ${senderName}`,
                    body: "You have new messages.",
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                console.log("Updated existing chat notification");
            } else {
                // Create new notification
                const notificationData = {
                    title: `New message from ${senderName}`,
                    body: "You have a new message.",
                    type: "chat",
                    chatId: context.params.chatId,
                    senderId: senderId,
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                };

                if (requestId) {
                    notificationData.requestId = requestId;
                }

                await notificationsRef.add(notificationData);
                console.log("Created new chat notification");
            }
            console.log("Chat notification saved to Firestore");


        } catch (error) {
            console.error("Error sending chat notification:", error);
        }
    });
