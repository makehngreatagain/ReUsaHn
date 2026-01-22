import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

// Trigger cuando se crea una nueva notificación en Firestore
export const sendNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const notification = snapshot.data();

    // Extraer datos de la notificación
    const {fcmToken, title, body, type, data} = notification;

    // Validar que existe un token FCM
    if (!fcmToken) {
      console.log("No FCM token found for notification");
      return null;
    }

    // Preparar el mensaje de notificación
    const message = {
      token: fcmToken,
      notification: {
        title: title || "ReUsa Honduras",
        body: body || "",
      },
      data: {
        type: type || "general",
        ...(data || {}),
      },
      android: {
        priority: "high" as const,
        notification: {
          sound: "default",
          icon: "@mipmap/ic_launcher",
          color: "#4CAF50",
        },
      },
    };

    try {
      // Enviar la notificación push
      const response = await admin.messaging().send(message);
      console.log("Successfully sent notification:", response);

      // Marcar la notificación como enviada
      await snapshot.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return response;
    } catch (error: any) {
      console.error("Error sending notification:", error);

      // Si el token es inválido, eliminarlo del usuario
      if (error.code === "messaging/invalid-registration-token" ||
          error.code === "messaging/registration-token-not-registered") {
        const userId = notification.userId;
        console.log(`Removing invalid FCM token for user: ${userId}`);

        await admin.firestore().collection("users").doc(userId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      }

      // Marcar como error
      await snapshot.ref.update({
        sent: false,
        error: error.message,
        errorCode: error.code || "unknown",
        erroredAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    }
  });
