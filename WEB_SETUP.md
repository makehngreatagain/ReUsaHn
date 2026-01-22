# Configuración de la Plataforma Web - ReUsa Honduras

## 🚀 Cómo ejecutar la plataforma web

### Opción 1: Modo desarrollo
```bash
flutter run -d chrome
```

### Opción 2: Compilar para producción
```bash
flutter build web --release
```

Los archivos compilados estarán en `build/web/`

## 🔧 Solución de problemas comunes

### Problema 1: Pantalla en blanco al ejecutar en Chrome

**Solución:**
1. Abre las herramientas de desarrollador de Chrome (F12)
2. Ve a la pestaña "Console" para ver errores
3. Verifica que Firebase esté configurado correctamente

**Comandos útiles:**
```bash
# Limpiar caché de Flutter
flutter clean
flutter pub get

# Ejecutar en modo debug con logs
flutter run -d chrome -v
```

### Problema 2: Error de Firebase en web

**Verificar que firebase_options.dart tenga la configuración web:**
El archivo `lib/firebase_options.dart` debe incluir:
- `webApiKey`
- `webAppId`
- `webMessagingSenderId`
- `webProjectId`
- `webAuthDomain`
- `webStorageBucket`

**Regenerar configuración de Firebase:**
```bash
flutterfire configure
```

### Problema 3: CORS errors (Cross-Origin)

Si ves errores de CORS en la consola, es porque Firebase Firestore requiere configuración adicional.

**Solución temporal para desarrollo:**
```bash
# Ejecutar Chrome sin seguridad CORS (solo para desarrollo)
chrome.exe --user-data-dir="C:/Chrome dev session" --disable-web-security
```

**Solución para producción:**
Asegúrate de que tu dominio esté configurado en Firebase Console:
1. Ve a Firebase Console → Authentication → Settings
2. Agrega tu dominio a "Authorized domains"

### Problema 4: Imagen o assets no cargan

**Verificar pubspec.yaml:**
```yaml
flutter:
  assets:
    - assets/images/
```

**Recompilar:**
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

## 📱 Ejecutar en diferentes navegadores

```bash
# Chrome
flutter run -d chrome

# Edge
flutter run -d edge

# Firefox (si está configurado)
flutter run -d firefox
```

## 🌐 Despliegue a producción

### Firebase Hosting
```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Inicializar hosting
firebase init hosting

# Compilar y desplegar
flutter build web --release
firebase deploy --only hosting
```

### Otras opciones de hosting
- **Netlify**: Arrastra la carpeta `build/web`
- **Vercel**: Conecta con tu repositorio GitHub
- **GitHub Pages**: Publica desde la carpeta `build/web`

## 🔐 Configuración de seguridad

### Reglas de Firestore para admin
Asegúrate de que solo los administradores puedan acceder a ciertas colecciones:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Verificar si el usuario es admin
    function isAdmin() {
      return request.auth != null &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Solo admins pueden leer/escribir en estas colecciones
    match /posts/{postId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /tree_plantings/{treeId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /reward_redemptions/{redemptionId} {
      allow read: if isAdmin();
      allow write: if isAdmin();
    }
  }
}
```

## 📊 Monitoreo y Analytics

Para habilitar analytics en web:

1. Agrega Firebase Analytics en `pubspec.yaml`:
```yaml
dependencies:
  firebase_analytics: ^latest_version
```

2. Inicializa en main.dart:
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  // ...
  if (kIsWeb) {
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    await analytics.logAppOpen();
  }
  // ...
}
```

## 🎨 Personalización

### Cambiar título y favicon

**Título:** Edita `web/index.html`
```html
<title>Tu Título Aquí</title>
```

**Favicon:** Reemplaza `web/favicon.png` con tu icono

### Cambiar colores del tema

Edita `lib/utils/colors.dart`:
```dart
class AppColors {
  static const Color primary = Color(0xFF4CAF50); // Tu color aquí
  // ...
}
```

## 📝 Notas importantes

1. **La plataforma web es SOLO para administradores**
   - Los usuarios regulares usan la app móvil
   - La web muestra automáticamente el login de admin

2. **Seguridad**
   - Siempre verifica el rol antes de permitir acciones
   - Usa reglas de seguridad de Firestore
   - No expongas credenciales en el código

3. **Performance**
   - La primera carga puede ser lenta
   - Considera usar caché y service workers
   - Optimiza imágenes antes de subirlas

## 📞 Soporte

Si tienes problemas:
1. Revisa la consola del navegador (F12)
2. Ejecuta `flutter doctor` para verificar configuración
3. Verifica que Firebase esté correctamente configurado
4. Limpia el proyecto con `flutter clean`
