# Setup Push Notification - MOEY Mobile

## 📱 Overview
Sistem push notification telah diimplementasikan menggunakan Firebase Cloud Messaging (FCM) untuk aplikasi MOEY Mobile.

## 🔧 Yang Sudah Dikerjakan

### 1. Dependencies yang Ditambahkan
```yaml
firebase_core: ^3.8.1
firebase_messaging: ^15.1.5
flutter_local_notifications: ^18.0.1
```

### 2. Service yang Dibuat
- **PushNotificationService** (`lib/services/push_notification_service.dart`)
  - Handle FCM token management
  - Handle foreground, background, dan terminated state notifications
  - Local notifications untuk show notification saat app di foreground
  - Stream untuk handle notification taps

### 3. Konfigurasi Android
- AndroidManifest.xml sudah dikonfigurasi dengan permissions dan meta-data FCM
- build.gradle sudah diupdate untuk support Firebase (minSdk 21)

### 4. Backend Integration
- Method `updateFCMToken()` sudah ditambahkan di NotificationService
- Endpoint: `POST /mobile/fcm-token` dengan body:
  ```json
  {
    "fcm_token": "...",
    "platform": "android"
  }
  ```

## 🚀 Setup Firebase Console

### Langkah 1: Buat Firebase Project
1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Klik "Add project" atau "Create a project"
3. Masukkan nama project: **MOEY Mobile**
4. Enable/disable Google Analytics (opsional)
5. Klik "Create project"

### Langkah 2: Tambahkan Android App
1. Di Firebase Console, pilih project MOEY Mobile
2. Klik ikon Android (Add Firebase to your Android app)
3. Isi form:
   - **Android package name**: `com.example.moey_mobile` (sesuai applicationId di build.gradle)
   - **App nickname**: MOEY Mobile (opsional)
   - **Debug signing certificate SHA-1**: (opsional, untuk development)
4. Klik "Register app"

### Langkah 3: Download google-services.json
1. Download file **google-services.json**
2. Copy file ke folder: `moey_mobile/android/app/`
3. Pastikan file berada di path yang benar:
   ```
   moey_mobile/
   └── android/
       └── app/
           ├── google-services.json  ← File ini
           ├── build.gradle.kts
           └── src/
   ```

### Langkah 4: Cloud Messaging Sudah Aktif
**Good news!** Cloud Messaging sudah otomatis enabled setelah Anda:
- Menambahkan Android app ke Firebase project
- Download file `google-services.json`

Tidak perlu konfigurasi tambahan di Firebase Console! Cloud Messaging API sudah aktif dan siap digunakan.

**Untuk melihat informasi Cloud Messaging**:
1. Di Firebase Console, klik ⚙️ (gear icon) di kiri atas
2. Pilih **Project settings**
3. Tab **Cloud Messaging**
4. Di sini Anda bisa lihat **Server key** dan **Sender ID** (untuk backend nanti)

### Langkah 5: Update build.gradle
Tambahkan Google Services plugin di `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Tambahkan ini dan hapus "apply false"
}
```

## 📦 Install Dependencies

Jalankan command berikut untuk install dependencies:

```bash
cd moey_mobile
flutter pub get
```

## 🏃 Running the App

```bash
flutter run
```

## 🧪 Testing Push Notifications

### 1. Testing dari Firebase Console (Simple Test)
**Cara 1: Menggunakan Composer (Notification Composer)**
1. Buka Firebase Console
2. Gunakan **Search bar** di atas, ketik **"Messaging"** atau **"Notifications"**
3. Atau bisa akses langsung: `https://console.firebase.google.com/project/YOUR_PROJECT_ID/notification`
4. Klik **"Send your first message"** atau **"New notification"**
5. Isi form:
   - **Notification title**: Test Notification
   - **Notification text**: This is a test push notification
6. Klik **"Send test message"** (tombol di kanan atas)
7. Masukkan **FCM Token** dari device Anda (lihat cara dapat token di bawah)
8. Klik **"+"** untuk add token, lalu klik **"Test"**

**Cara 2: Direct URL (Jika tidak ketemu menu)**
Akses langsung ke: `https://console.firebase.google.com/project/YOUR_PROJECT_ID/notification`
(Ganti `YOUR_PROJECT_ID` dengan ID project Anda)

**Cara mendapatkan FCM Token dari App**:
- Jalankan app di device/emulator
- Check console log, akan muncul: `FCM Token: xxxxxxxxxxxxxx`
- Copy token tersebut untuk testing

### 2. Testing dengan Backend API
Backend perlu mengirim POST request ke FCM API:

```http
POST https://fcm.googleapis.com/fcm/send
Content-Type: application/json
Authorization: key=YOUR_SERVER_KEY

{
  "to": "FCM_TOKEN_DARI_USER",
  "notification": {
    "title": "New Notification",
    "body": "You have a new order notification"
  },
  "data": {
    "notification_id": "123",
    "order_id": "456",
    "type": "order_update"
  }
}
```

**Server Key** bisa didapat dari:
Firebase Console > Project Settings > Cloud Messaging > Server Key

## 🔐 Backend Implementation (Laravel)

### 1. Buat Migration untuk FCM Token

```bash
php artisan make:migration add_fcm_token_to_users_table
```

```php
// database/migrations/xxxx_add_fcm_token_to_users_table.php
public function up()
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('fcm_token')->nullable()->after('remember_token');
        $table->string('fcm_platform')->nullable()->after('fcm_token'); // android/ios
    });
}

public function down()
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn(['fcm_token', 'fcm_platform']);
    });
}
```

### 2. Update User Model

```php
// app/Models/User.php
protected $fillable = [
    // ... existing fields
    'fcm_token',
    'fcm_platform',
];
```

### 3. Buat Route untuk Update FCM Token

```php
// routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/mobile/fcm-token', [MobileController::class, 'updateFCMToken']);
});
```

### 4. Buat Controller Method

```php
// app/Http/Controllers/MobileController.php
public function updateFCMToken(Request $request)
{
    $request->validate([
        'fcm_token' => 'required|string',
        'platform' => 'required|in:android,ios',
    ]);

    $user = $request->user();
    $user->update([
        'fcm_token' => $request->fcm_token,
        'fcm_platform' => $request->platform,
    ]);

    return response()->json([
        'success' => true,
        'message' => 'FCM token updated successfully',
    ]);
}
```

### 5. Install FCM Package (Laravel)

```bash
composer require kreait/firebase-php
```

### 6. Buat Service untuk Send Push Notification

```php
// app/Services/FirebaseNotificationService.php
<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;

class FirebaseNotificationService
{
    protected $messaging;

    public function __construct()
    {
        // Path ke firebase service account JSON file
        $factory = (new Factory)->withServiceAccount(storage_path('app/firebase-service-account.json'));
        $this->messaging = $factory->createMessaging();
    }

    public function sendToDevice($fcmToken, $title, $body, $data = [])
    {
        try {
            $message = CloudMessage::withTarget('token', $fcmToken)
                ->withNotification([
                    'title' => $title,
                    'body' => $body,
                ])
                ->withData($data);

            $this->messaging->send($message);
            
            return true;
        } catch (\Exception $e) {
            \Log::error('FCM Send Error: ' . $e->getMessage());
            return false;
        }
    }

    public function sendToMultipleDevices($fcmTokens, $title, $body, $data = [])
    {
        try {
            $message = CloudMessage::new()
                ->withNotification([
                    'title' => $title,
                    'body' => $body,
                ])
                ->withData($data);

            $this->messaging->sendMulticast($message, $fcmTokens);
            
            return true;
        } catch (\Exception $e) {
            \Log::error('FCM Multicast Error: ' . $e->getMessage());
            return false;
        }
    }
}
```

### 7. Download Firebase Service Account JSON

1. Firebase Console > Project Settings > Service Accounts
2. Klik "Generate new private key"
3. Download JSON file
4. Save ke: `storage/app/firebase-service-account.json`
5. Tambahkan ke `.gitignore`:
   ```
   storage/app/firebase-service-account.json
   ```

### 8. Kirim Notification saat ada Order Baru

```php
// Di controller atau event listener ketika ada notification baru
use App\Services\FirebaseNotificationService;

public function createNotification($userId, $title, $message, $data = [])
{
    // Simpan notification ke database
    $notification = Notification::create([
        'user_id' => $userId,
        'title' => $title,
        'message' => $message,
        'data' => $data,
    ]);

    // Kirim push notification
    $user = User::find($userId);
    if ($user && $user->fcm_token) {
        $fcmService = new FirebaseNotificationService();
        $fcmService->sendToDevice(
            $user->fcm_token,
            $title,
            $message,
            [
                'notification_id' => (string)$notification->id,
                'type' => $data['type'] ?? 'general',
            ]
        );
    }

    return $notification;
}
```

## 📱 Notification States yang Dihandle

### 1. **Foreground** (App Terbuka)
- Notification muncul via local notification
- User bisa tap untuk navigate ke NotificationScreen

### 2. **Background** (App di background)
- Notification muncul di notification bar
- Tap notification buka app dan navigate ke NotificationScreen

### 3. **Terminated** (App ditutup)
- Notification muncul di notification bar
- Tap notification buka app dan navigate ke NotificationScreen

## 🎨 Notification Format

### Dari Backend ke FCM:
```json
{
  "notification": {
    "title": "Order Baru",
    "body": "Anda mendapat order baru dari Customer ABC"
  },
  "data": {
    "notification_id": "123",
    "order_id": "456",
    "type": "order_new",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

## 🔍 Debugging

### Check FCM Token di App:
FCM token akan di-print di console saat app start:
```
FCM Token: xxxxxxxxxxxxxxxxxxxxxx
```

### Check di Logcat (Android):
```bash
flutter logs
```

Atau:
```bash
adb logcat | grep FCM
```

## ⚠️ Common Issues

### 1. "FirebaseApp not initialized"
**Solution**: Pastikan `google-services.json` sudah di-copy ke `android/app/`

### 2. "Default FirebaseApp failed to initialize"
**Solution**: 
- Clean build: `flutter clean && flutter pub get`
- Rebuild: `flutter run`

### 3. Notification tidak muncul di foreground
**Solution**: Cek apakah local notification channel sudah dibuat dengan benar

### 4. "Missing google-services.json"
**Solution**: Download dari Firebase Console dan copy ke `android/app/`

## 📚 Resources

- [Firebase Console](https://console.firebase.google.com/)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging](https://firebase.flutter.dev/docs/messaging/overview/)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

## ✅ Next Steps

1. ✅ Download `google-services.json` dari Firebase Console
2. ✅ Copy ke `moey_mobile/android/app/`
3. ✅ Update `android/app/build.gradle.kts` - hapus `apply false` dari google-services plugin
4. ✅ Run `flutter pub get`
5. ✅ Implement backend migration dan service
6. ✅ Test push notification dari Firebase Console
7. ✅ Integrate dengan backend untuk auto-send notification

## 🎉 Selesai!

Push notification system sudah siap digunakan. Tinggal setup Firebase Console dan implement backend side untuk send notifications.
