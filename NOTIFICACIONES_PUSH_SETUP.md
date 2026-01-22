# Configuración de Notificaciones Push - ReUsa Honduras

## ⚠️ IMPORTANTE

Las notificaciones push están **parcialmente implementadas** en la aplicación Flutter. Para que funcionen completamente, necesitas configurar **Firebase Cloud Functions** que envíen las notificaciones reales usando la API de Firebase Cloud Messaging (FCM).

## 📋 Estado Actual

### ✅ Implementado en la App Flutter:
- ✅ Servicio de notificaciones (`NotificationService`)
- ✅ Solicitud de permisos de notificaciones
- ✅ Registro y almacenamiento de FCM tokens
- ✅ Listeners para recibir notificaciones
- ✅ Notificaciones locales cuando la app está abierta
- ✅ Creación de registros en Firestore (`notifications` collection)
- ✅ Integración en todos los servicios:
  - Publicaciones (aprobar/rechazar)
  - Mensajes de chat
  - Árboles plantados (aprobar)
  - Propuestas de intercambio
  - Confirmación de intercambios

### ❌ Falta Implementar (Cloud Functions):
- ❌ Trigger de Firestore que detecte nuevas notificaciones
- ❌ Envío real de notificaciones push via FCM Admin SDK
- ❌ Manejo de errores de tokens inválidos

---

## 🚀 Cómo Funciona Actualmente

### Flujo Actual (SIN Cloud Functions):

1. **Usuario realiza acción** (ej: envía mensaje)
2. **Servicio crea registro** en Firestore `notifications` collection:
```javascript
{
  userId: "abc123",
  title: "Nuevo Mensaje",
  body: "Juan te envió un mensaje",
  type: "chat_message",
  fcmToken: "token_del_usuario",
  data: { chatId: "xyz" },
  isRead: false,
  createdAt: timestamp
}
```
3. **❌ NOTIFICACIÓN NO SE ENVÍA** (porque falta Cloud Function)
4. Si el usuario tiene la app abierta, verá notificación local

---

## 🔧 Implementación de Cloud Functions (Paso a Paso)

### Requisito Previo:
- Node.js 18+ instalado
- Firebase CLI instalado: `npm install -g firebase-tools`
- Proyecto de Firebase ya configurado

### Paso 1: Inicializar Cloud Functions

```bash
cd /path/to/tu/proyecto
firebase login
firebase init functions
```

Selecciona:
- JavaScript o TypeScript (recomendado: TypeScript)
- Instalar dependencias: Sí

### Paso 2: Instalar Dependencias

```bash
cd functions
npm install firebase-admin
npm install firebase-functions
```

### Paso 3: Crear la Cloud Function

Edita `functions/src/index.ts` (o `index.js`):

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

// Trigger cuando se crea una nueva notificación
export const sendNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const notification = snapshot.data();

    // Extraer datos
    const { fcmToken, title, body, type, data } = notification;

    // Validar que existe un token
    if (!fcmToken) {
      console.log("No FCM token found");
      return null;
    }

    // Preparar el mensaje
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
      // Enviar la notificación
      const response = await admin.messaging().send(message);
      console.log("Successfully sent notification:", response);

      // Opcionalmente, marcar como enviada
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
        await admin.firestore().collection("users").doc(userId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      }

      return null;
    }
  });
```

### Paso 4: Desplegar Cloud Functions

```bash
firebase deploy --only functions
```

### Paso 5: Verificar en Firebase Console

1. Ve a Firebase Console → Functions
2. Deberías ver `sendNotification` desplegada
3. Verifica los logs: Firebase Console → Functions → Logs

---

## 🧪 Probar las Notificaciones

### Opción 1: Desde la App
1. Inicia sesión con un usuario
2. Realiza una acción que genere notificación (ej: otro usuario te envía mensaje)
3. Verifica que llegue la notificación push

### Opción 2: Manualmente desde Firestore
1. Ve a Firestore en Firebase Console
2. Crea manualmente un documento en `notifications`:
```javascript
{
  userId: "TU_USER_ID",
  title: "Test",
  body: "Esto es una prueba",
  type: "test",
  fcmToken: "TU_FCM_TOKEN", // Copia el token de tu usuario en la colección users
  isRead: false,
  createdAt: [timestamp actual]
}
```
3. La Cloud Function se activará automáticamente

---

## 📊 Colección de Notificaciones (Firestore)

### Estructura de Documento:

```typescript
{
  userId: string,        // ID del usuario destinatario
  title: string,         // Título de la notificación
  body: string,          // Cuerpo del mensaje
  type: string,          // Tipo: chat_message, post_approved, tree_approved, etc.
  fcmToken: string,      // Token FCM del usuario
  data?: object,         // Datos adicionales (chatId, postId, etc.)
  isRead: boolean,       // Si el usuario la leyó
  sent?: boolean,        // Si la Cloud Function la envió
  sentAt?: timestamp,    // Cuándo se envió
  createdAt: timestamp   // Cuándo se creó
}
```

### Índices Recomendados:

```json
{
  "collectionGroup": "notifications",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "notifications",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "isRead", "order": "ASCENDING" }
  ]
}
```

---

## 🎯 Tipos de Notificaciones Implementadas

| Tipo | Cuándo se Envía | Título | Cuerpo |
|------|----------------|--------|--------|
| `post_approved` | Admin aprueba publicación | "Publicación Aprobada" | "Tu publicación ha sido aprobada..." |
| `post_rejected` | Admin rechaza publicación | "Publicación Rechazada" | "Tu publicación fue rechazada..." |
| `chat_message` | Usuario recibe mensaje | Nombre del remitente | Texto del mensaje |
| `tree_approved` | Admin aprueba árbol | "¡Árbol Aprobado! 🌳" | "Tu árbol plantado ha sido aprobado..." |
| `exchange_proposed` | Usuario recibe propuesta | "💱 Nueva Propuesta de Intercambio" | "{Nombre} te propone un intercambio..." |
| `exchange_confirmed` | Intercambio confirmado | "✅ Intercambio Confirmado" | "{Nombre} ha confirmado el intercambio..." |

---

## 🔐 Seguridad (Firestore Rules)

Agrega estas reglas para la colección `notifications`:

```javascript
match /notifications/{notificationId} {
  // Solo el usuario dueño puede leer sus notificaciones
  allow read: if request.auth != null &&
                 resource.data.userId == request.auth.uid;

  // Solo el sistema (Cloud Functions) puede escribir notificaciones
  // Las apps no deben crear notificaciones directamente
  allow write: if false;
}
```

**Nota:** Las notificaciones se crean desde los servicios de la app usando credenciales admin de Firebase.

---

## ⚡ Optimizaciones Avanzadas (Opcional)

### 1. Envío en Batch para Múltiples Usuarios

Si necesitas enviar a muchos usuarios:

```typescript
export const sendBatchNotifications = functions.firestore
  .document("batch_notifications/{batchId}")
  .onCreate(async (snapshot) => {
    const batch = snapshot.data();
    const { userIds, title, body, type } = batch;

    // Obtener tokens de todos los usuarios
    const usersSnapshot = await admin.firestore()
      .collection("users")
      .where(admin.firestore.FieldPath.documentId(), "in", userIds)
      .get();

    const tokens = usersSnapshot.docs
      .map(doc => doc.data().fcmToken)
      .filter(token => token);

    // Enviar a todos
    const message = {
      notification: { title, body },
      data: { type },
      tokens,
    };

    await admin.messaging().sendMulticast(message);
  });
```

### 2. Notificaciones Programadas

Usa Cloud Scheduler + Pub/Sub para enviar notificaciones en horarios específicos.

### 3. Analytics de Notificaciones

Agrega seguimiento de cuántas notificaciones se abren:

```typescript
// En la app Flutter, cuando el usuario toca la notificación
await FirebaseFirestore.instance
  .collection('notifications')
  .doc(notificationId)
  .update({
    'opened': true,
    'openedAt': FieldValue.serverTimestamp(),
  });
```

---

## 🐛 Troubleshooting

### Problema: No llegan notificaciones

**Checklist:**
1. ✅ ¿La Cloud Function está desplegada? (verifica en Firebase Console)
2. ✅ ¿El usuario tiene `fcmToken` en Firestore?
3. ✅ ¿La app tiene permisos de notificaciones?
4. ✅ ¿El documento en `notifications` se creó correctamente?
5. ✅ Revisa los logs de Cloud Functions

### Problema: Token inválido

Si ves errores de token inválido:
- El usuario desinstalóborró datos de la app
- La Cloud Function automáticamente elimina tokens inválidos
- El usuario debe volver a hacer login para generar nuevo token

### Problema: Notificaciones duplicadas

- Verifica que no estés creando el mismo documento dos veces
- Usa `.set()` con merge en lugar de `.add()`

---

## 📱 Testing en Desarrollo

### Opción 1: Firebase Console

1. Firebase Console → Cloud Messaging
2. "Send test message"
3. Pega el FCM token del dispositivo
4. Envía

### Opción 2: cURL

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "DEVICE_FCM_TOKEN",
      "notification": {
        "title": "Test",
        "body": "Mensaje de prueba"
      }
    }
  }'
```

---

## 📚 Recursos Adicionales

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Messaging Flutter](https://pub.dev/packages/firebase_messaging)

---

## ✅ Checklist de Implementación

- [x] NotificationService creado en Flutter
- [x] Permisos agregados en AndroidManifest
- [x] FCM tokens se guardan en Firestore
- [x] Registros de notificaciones se crean
- [x] Listeners configurados en main.dart
- [ ] **Cloud Functions desplegadas** ⚠️ PENDIENTE
- [ ] **Probado en dispositivo real** ⚠️ PENDIENTE
- [ ] **Firestore Rules configuradas** ⚠️ PENDIENTE

---

## 🎉 Resultado Final

Una vez desplegadas las Cloud Functions, los usuarios recibirán notificaciones push automáticas cuando:

✅ Alguien les envíe un mensaje
✅ Se apruebe su publicación
✅ Se apruebe su árbol plantado
✅ Reciban propuesta de intercambio
✅ Se confirme un intercambio

**¡Las notificaciones están listas del lado de Flutter! Solo falta desplegar las Cloud Functions.**
