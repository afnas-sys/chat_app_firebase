const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationOnMessage = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        const message = snapshot.data();
        const chatId = context.params.chatId;

        // 1. Skip if it's a system message
        if (message.isSystemMessage) return null;

        const senderId = message.senderId;
        const senderName = (message.user && message.user.firstName) || "New Message";
        const text = message.text || "Sent an attachment";

        try {
            // 2. Get the Chat document to find the recipients
            const chatDoc = await admin.firestore().collection("chats").doc(chatId).get();
            if (!chatDoc.exists) {
                console.log("Chat document not found:", chatId);
                return null;
            }

            const chatData = chatDoc.data();
            const isGroup = chatData.isGroup || false;
            const groupName = chatData.groupName || "Group Chat";

            let recipientIds = [];
            if (isGroup) {
                // For groups, send to all members except the sender
                // Assuming 'users' array exists in the chat doc
                recipientIds = (chatData.users || []).filter((uid) => uid !== senderId);
            } else {
                // For 1-on-1, the receiverId is usually in the message or derived from 'users'
                // Let's check both possibilities
                if (message.receiverId) {
                    recipientIds = [message.receiverId];
                } else if (chatData.users) {
                    recipientIds = chatData.users.filter((uid) => uid !== senderId);
                }
            }

            if (recipientIds.length === 0) {
                console.log("No recipients identified for message:", snapshot.id);
                return null;
            }

            // 3. Fetch FCM tokens for all recipients
            const tokens = [];
            const userDocs = await Promise.all(
                recipientIds.map((uid) => admin.firestore().collection("users").doc(uid).get())
            );

            userDocs.forEach((doc) => {
                if (doc.exists && doc.data().fcmToken) {
                    tokens.push(doc.data().fcmToken);
                }
            });

            if (tokens.length === 0) {
                console.log("No FCM tokens found for recipients:", recipientIds);
                return null;
            }

            // 4. Create the notification payload
            // Using multicast for sending to multiple tokens efficiently
            const messagePayload = {
                tokens: tokens,
                notification: {
                    title: isGroup ? `${groupName}` : senderName,
                    body: isGroup ? `${senderName}: ${text}` : text,
                },
                android: {
                    notification: {
                        channelId: "high_importance_channel",
                        priority: "high",
                        visibility: "public",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            badge: 1,
                        },
                    },
                },
                data: {
                    chatId: chatId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
            };

            // 5. Send the notifications
            const response = await admin.messaging().sendEachForMulticast(messagePayload);
            console.log(`Successfully sent ${response.successCount} notifications. failed: ${response.failureCount}`);

            // Optional: Cleanup invalid tokens
            if (response.failureCount > 0) {
                const failedTokens = [];
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        failedTokens.push(tokens[idx]);
                    }
                });
                console.log("Failed tokens count:", failedTokens.length);
            }

            return null;
        } catch (error) {
            console.error("Error in sendNotificationOnMessage:", error);
            return null;
        }
    });
