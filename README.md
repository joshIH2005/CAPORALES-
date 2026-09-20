# Caporales App

App móvil Android (Flutter) para gestionar un **elenco de danza Caporales**: registro rápido de asistencia y cobro de aportes (S/ 1.00 por ensayo) escaneando códigos QR, con sincronización en tiempo real vía **Google Sheets**.

## Estructura del proyecto

```text
lib/
├── main.dart                  # Entrada de la app + tema Material 3 oscuro
├── core/
│   ├── constants/             # Colores, estilos de texto, config de API
│   └── utils/                 # Formateadores y validadores
├── data/
│   ├── models/                # Member (integrante) y Record (registro)
│   └── providers/             # ApiService (HTTP hacia Google Apps Script)
├── logic/
│   └── member_controller.dart # Estado global (ChangeNotifier)
└── ui/
    ├── screens/               # dashboard, scanner, add_member
    ├── widgets/               # carnet digital, compartir, metricas
    └── layouts/               # navegacion principal
backend/
└── appsscript.gs              # Backend Google Apps Script
```

## Instalación

### 1. Entorno (una sola vez)

1. Descarga e instala el **Flutter SDK** desde [flutter.dev](https://flutter.dev) y agrega `flutter\bin` al PATH.
2. Instala **Android Studio** (incluye Android SDK + Build-Tools + Emulador).
3. Instala **VS Code** con las extensiones **Flutter** y **Dart**.

### 2. Generar los archivos de plataforma

Este repositorio contiene el código (`lib/`, `pubspec.yaml`). Los archivos de compilación de Android se generan con:

```bash
flutter create --org com.tuorganizacion --project-name caporales_app .
flutter pub get
```

> El `AndroidManifest.xml` ya está configurado con el permiso de cámara.

### 3. Configurar el backend (Google Sheets + Apps Script)

1. Crea una hoja de cálculo en Google Drive llamada `Caporales` (o usa el ID en `backend/appsscript.gs`).
2. Entra a [script.google.com](https://script.google.com), crea un proyecto nuevo y pega el contenido de `backend/appsscript.gs`.
3. Ve a **Implementar > Nuevo despliegue > Aplicación web**:
   - **Ejecutar como:** Yo
   - **Acceso:** Cualquier persona (o Solo usuarios)
4. Copia la URL generada (termina en `/exec`) y pégala en:

```dart
// lib/core/constants/api_config.dart
static const String baseUrl = 'https://script.google.com/macros/s/TU_WEB_APP_ID/exec';
```

> **Seguridad:** todas las peticiones incluyen un token secreto. Define el
> mismo valor en `API_TOKEN` en `backend/appsscript.gs` y en
> `ApiConfig.tokenSecreto` en la app antes de publicar. Los QR de los
> carnets se firman con `ApiConfig.qrClaveSecreta` (mismo valor que
> `QR_CLAVE` en el backend). No publiques datos reales sin reemplazar los
> valores de ejemplo.

> **Escrituras:** la app usa **POST** para registrar integrantes/pagos y
> maneja el redirect (302) de Apps Script manualmente. Si despliegas una
> versión antigua, sigue aceptando escrituras por GET con token.

### 4. Ejecutar la app

Conecta tu Android por USB (con Depuración USB activada) o inicia el emulador:

```bash
flutter run
```

Con **Hot Reload** (`r` o guardando el archivo) verás los cambios en segundos.

### 5. Cambiar el ícono (opcional)

1. Guarda tu logo en `assets/images/logo_elenco.png` (1024x1024 px).
2. Agrega en `pubspec.yaml` bajo `dev_dependencies`:
   ```yaml
   flutter_launcher_icons: ^0.13.1
   ```
3. Ejecuta:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

## Uso

- **Dashboard:** total recaudado, integrantes, pagos y lista de inasistencias críticas (+14 días).
- **Escáner:** enfoca el QR del carnet → registra el pago (S/ 1.00) y muestra el resultado.
- **Nuevo:** formulario de alta + carnet digital generado y compartible como imagen.