# LPMI40 - Lagu Pujian Masa Ini

<div align="center">
  <img src="assets/images/header_image.png" alt="LPMI40 Logo" width="200"/>
  
  **A Modern Christian Hymn Book Application**
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
  
  *Browse, search, and enjoy Christian hymns with modern features*
</div>

## 📖 About

LPMI40 (Lagu Pujian Masa Ini) is a comprehensive digital hymn book application designed for modern Christian worship. Built with Flutter and powered by Firebase, it offers a seamless experience for browsing, reading, and managing your favorite hymns with advanced features like cloud synchronization, customizable themes, and collaborative song management.

## ✨ Features

### 🎵 **Core Features**
- **Complete Hymn Library** - Browse hundreds of Christian hymns
- **Smart Search** - Find songs by number, title, or lyrics
- **Favorites System** - Save and organize your favorite hymns
- **Verse of the Day** - Daily inspirational verses
- **Share & Copy** - Easily share hymns with others
- **Offline Access** - Read hymns without internet connection

### 🎨 **Customization**
- **Dark Mode** - Eye-friendly dark theme support
- **8 Color Themes** - Blue, Green, Purple, Orange, Red, Teal, Indigo, Pink
- **Font Customization** - Adjustable size (12-30px) and family
- **Text Alignment** - Left, center, or right alignment
- **Responsive Design** - Works on all screen sizes

### 👤 **User Management**
- **Guest Mode** - Browse without registration
- **User Registration** - Full account with cloud sync
- **Profile Management** - Custom photos and display names
- **Secure Authentication** - Firebase-powered login system
- **Password Management** - Change passwords securely

### ☁️ **Cloud Features**
- **Cross-Device Sync** - Access favorites anywhere
- **Real-time Updates** - Latest hymns automatically synced
- **Backup & Restore** - Never lose your data
- **Online/Offline Status** - Clear connection indicators

### 📊 **Admin Features**
- **Song Management** - Add, edit, and organize hymns
- **Report Management** - Handle user feedback and issues
- **User Analytics** - Track usage and engagement
- **Content Moderation** - Maintain quality standards

### 🔧 **Advanced Features**
- **Song Reporting** - Users can report issues (registered users only)
- **Firebase Integration** - Real-time database and authentication
- **Error Handling** - Graceful error recovery
- **Performance Monitoring** - Optimized for smooth experience

## 🚀 User Types & Access Levels

### 👥 **Guest Users (Anonymous)**
- ✅ Browse all hymns
- ✅ View verse of the day
- ✅ Access settings and themes
- ✅ Use search and filters
- ❌ Cannot save favorites
- ❌ Cannot report songs
- ❌ No cloud sync

### 🔑 **Registered Users**
- ✅ All guest features
- ✅ Save and sync favorites
- ✅ Report song issues
- ✅ Profile customization
- ✅ Cross-device synchronization
- ✅ Password management

### 👑 **Admin Users**
- ✅ All registered user features
- ✅ Add new hymns
- ✅ Edit existing songs
- ✅ Manage song reports
- ✅ Content moderation
- ❌ No user management

### 🛡️ **Super Admin Users**
- ✅ All admin features
- ✅ User management
- ✅ Firebase debugging
- ✅ System administration
- ✅ Full access control

## 🛠️ Technical Stack

### **Frontend**
- **Flutter 3.0+** - Cross-platform mobile framework
- **Material Design 3** - Modern UI components
- **Provider** - State management
- **Dart** - Programming language

### **Backend**
- **Firebase Authentication** - User management
- **Firebase Realtime Database** - Data storage
- **Firebase Storage** - File storage
- **Cloud Functions** - Server-side logic

### **Features**
- **Responsive Design** - Adaptive layouts
- **Offline Support** - Local data caching
- **Push Notifications** - Real-time updates
- **Analytics** - Usage tracking

## 📱 Screenshots

### Light Mode
- Dashboard with daily verse
- Song browsing interface
- Lyrics display with customization
- Settings and theme selection

### Dark Mode
- Professional dark interface
- High contrast readability
- Consistent theming
- Eye-friendly design

## 🔧 Installation

### **Prerequisites**
- Flutter 3.0 or higher
- Dart SDK 3.0 or higher
- Firebase project setup
- Android Studio / VS Code

### **Setup**
1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/lpmi40.git
   cd lpmi40
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add `google-services.json` (Android)
   - Add `GoogleService-Info.plist` (iOS)
   - Update Firebase configuration

4. **Run the app**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```
lib/
├── src/
│   ├── core/
│   │   ├── services/          # Core services
│   │   ├── theme/             # App theming
│   │   └── utils/             # Utility functions
│   ├── features/
│   │   ├── authentication/    # User auth
│   │   ├── dashboard/         # Main dashboard
│   │   ├── songbook/          # Song features
│   │   ├── settings/          # App settings
│   │   ├── admin/             # Admin features
│   │   └── reports/           # Reporting system
│   └── main.dart              # App entry point
├── assets/
│   ├── images/                # App images
│   └── fonts/                 # Custom fonts
└── pubspec.yaml               # Dependencies
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit your changes**
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. **Push to the branch**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**

### **Code Guidelines**
- Follow Flutter/Dart conventions
- Add comments for complex logic
- Write tests for new features
- Ensure responsive design
- Test on multiple devices

## 📋 Roadmap

### **Version 2.1.0**
- [ ] Offline song downloads
- [ ] Audio playback support
- [ ] Advanced search filters
- [ ] Song categories/tags
- [ ] Playlist creation

### **Version 2.2.0**
- [ ] Social features (sharing playlists)
- [ ] Multi-language support
- [ ] Accessibility improvements
- [ ] Performance optimizations
- [ ] Widget for home screen

### **Future Releases**
- [ ] Web application
- [ ] Desktop support
- [ ] API for third-party integration
- [ ] Advanced analytics
- [ ] Machine learning recommendations

## 🐛 Bug Reports & Feature Requests

Found a bug or have a feature idea? We'd love to hear from you!

1. **Check existing issues** first
2. **Create a detailed issue** with:
   - Device information
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable

## 📞 Support

- **Email**: support@haweeinc.com
- **Documentation**: [Wiki](https://github.com/yourusername/lpmi40/wiki)
- **FAQ**: [Frequently Asked Questions](https://github.com/yourusername/lpmi40/wiki/FAQ)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **HaweeInc** - Development and design
- **Firebase** - Backend infrastructure
- **Flutter Team** - Amazing framework
- **Contributors** - Community support
- **Users** - Feedback and suggestions

## 📊 Statistics

- **Songs**: 500+ hymns available
- **Users**: Growing community
- **Downloads**: Available on stores
- **Rating**: ⭐⭐⭐⭐⭐ User-loved
- **Updates**: Regular feature releases

---

<div align="center">
  <p><strong>Made with ❤️ by HaweeInc</strong></p>
  <p><em>Lagu Pujian Masa Ini © 2024</em></p>
  
  [Download on Google Play](https://play.google.com/store/apps/details?id=com.haweeinc.lpmi_premium) | 
  [Visit Website](https://haweeinc.com) | 
  [Report Issues](https://github.com/yourusername/lpmi40/issues)
</div>