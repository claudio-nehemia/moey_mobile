# MOEY Mobile - Notification System

Aplikasi mobile Flutter untuk sistem notifikasi MOEY Project Management.

## Fitur Utama

✅ **Authentication**
- Login dengan email dan password
- Auto-login jika sudah pernah login
- Logout dengan konfirmasi

✅ **Notifications**
- Tampilkan semua notifikasi dari backend
- Filter notifikasi: All, Unread, Read
- Mark as read individual notification
- Mark all as read
- Real-time polling setiap 30 detik
- Badge unread count
- Pull to refresh

✅ **UI/UX**
- Splash screen dengan auto-check login status
- Design konsisten dengan tema interior design
- Icon dan warna berbeda per tipe notifikasi
- Time ago format untuk timestamp
- Loading indicators

## Setup & Installation

### 1. Install Dependencies

```bash
cd moey_mobile
flutter pub get
```

### 2. Configure Backend URL

Edit file `lib/utils/constant.dart`:

```dart
static const String baseUrl = 'http://192.168.204.146:8000/api'; // Your IP
```

**Penting:**
- Untuk Android Emulator: gunakan `http://10.0.2.2:8000/api`
- Untuk Physical Device: gunakan IP komputer Anda (cek dengan `ipconfig`)
- Untuk iOS Simulator: gunakan `http://localhost:8000/api` atau IP komputer

### 3. Pastikan Backend Laravel Berjalan

```bash
cd ../MoeyBackendAdmin
php artisan serve --host=0.0.0.0 --port=8000
```

Backend akan berjalan di `http://0.0.0.0:8000` dan bisa diakses dari semua network interface.

### 4. Run Flutter App

```bash
# Untuk Android
flutter run

# Atau pilih device spesifik
flutter devices
flutter run -d <device-id>
```

## Struktur Folder

```
lib/
├── main.dart                    # Entry point & splash screen
├── models/
│   ├── user.dart               # User model
│   ├── notification.dart       # Notification & Order model
│   └── auth_response.dart      # Auth response model
├── services/
│   ├── auth_service.dart       # Auth logic (login, logout, token)
│   └── notification_service.dart # Notification API calls
├── screens/
│   ├── login_screen.dart       # Login UI
│   └── notification_screen.dart # Notification list UI
└── utils/
    └── constant.dart           # Constants (API URL, colors)
```

## API Endpoints Yang Digunakan

### Authentication
- `POST /api/login` - Login user
- `POST /api/logout` - Logout user
- `GET /api/me` - Get current user

### Notifications
- `GET /api/notifications` - Get notifications (with filter & pagination)
- `GET /api/notifications/unread-count` - Get unread count
- `POST /api/notifications/{id}/mark-as-read` - Mark as read
- `POST /api/notifications/mark-all-as-read` - Mark all as read

## Tipe Notifikasi

Aplikasi support berbagai tipe notifikasi sesuai dengan backend:

1. **Survey Request** - Icon: Assignment, Color: Blue
2. **Moodboard Request** - Icon: Design Services, Color: Purple
3. **Estimasi Request** - Icon: Calculate, Color: Orange
4. **Design Approval** - Icon: Design Services, Color: Purple
5. **Commitment Fee Request** - Icon: Payment, Color: Green
6. **Final Design Request** - Icon: Design Services, Color: Purple
7. **Item Pekerjaan Request** - Icon: Build, Color: Primary
8. **RAB Internal Request** - Icon: Calculate, Color: Orange
9. **Kontrak Request** - Icon: Description, Color: Red
10. **Invoice Request** - Icon: Payment, Color: Green
11. **Survey Ulang Request** - Icon: Assignment, Color: Blue
12. **Workplan Request** - Icon: Calendar, Color: Primary
13. **Project Management Request** - Icon: Account Tree, Color: Primary

## Testing

### Test Credentials

Gunakan user dari database Laravel Anda. Contoh:
- Email: `admin@moey.com`
- Password: (sesuai database)

### Troubleshooting

**1. Error: Connection refused**
- Pastikan backend Laravel running di `http://0.0.0.0:8000`
- Pastikan IP di `constant.dart` sudah benar
- Cek firewall Windows tidak block port 8000
- Test API dengan browser: `http://192.168.204.146:8000/api/me`

**2. Error: No authentication token**
- Logout dan login ulang
- Clear app data di device/emulator

**3. Notifikasi tidak muncul**
- Pastikan user yang login memiliki notifikasi di database
- Cek role user sesuai dengan notifikasi
- Test API langsung: `http://192.168.204.146:8000/api/notifications`

**4. Polling tidak berjalan**
- Notifikasi akan auto-refresh setiap 30 detik
- Bisa juga pull to refresh manual

## Dependencies

```yaml
dependencies:
  http: ^1.1.0              # HTTP client
  provider: ^6.1.1          # State management (siap jika butuh)
  shared_preferences: ^2.2.2 # Local storage
  flutter_spinkit: ^5.2.0   # Loading indicators
  cupertino_icons: ^1.0.2   # iOS icons
```

## Next Steps & Future Improvements

- [ ] Add push notifications (FCM)
- [ ] Add notification detail page
- [ ] Add deep linking to order details
- [ ] Add offline mode & sync
- [ ] Add notification settings
- [ ] Add dark mode
- [ ] Add localization (ID/EN)
- [ ] Add unit tests

## Development Notes

### Backend Changes Made

1. **Added API Controller**: `NotificationApiController.php`
   - GET /api/notifications - List notifications
   - GET /api/notifications/unread-count
   - POST /api/notifications/{id}/mark-as-read
   - POST /api/notifications/mark-all-as-read

2. **Updated Routes**: `routes/api.php`
   - Added notification routes under `auth:sanctum` middleware

### Flutter Architecture

- **Services Layer**: Handle API calls & business logic
- **Models**: Data structures matching backend
- **Screens**: UI components
- **Constants**: Centralized configuration

---

**Created by:** GitHub Copilot  
**Date:** December 17, 2025  
**Backend:** Laravel Sanctum  
**Frontend:** Flutter  
**Network:** 192.168.204.146:8000
