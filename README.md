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
- **Complete Hymn Library** - Browse hundreds of Christian hymns across multiple collections
- **Smart Search** - Intelligent search-first discovery with real-time results across song numbers, titles, and lyrics
- **Collection Previews** - Quick access to popular and recent songs from each collection
- **Favorites System** - Save and organize your favorite hymns with collection grouping
- **Verse of the Day** - Daily inspirational verses
- **Share & Copy** - Easily share hymns with others
- **Offline Access** - Read hymns without internet connection with automatic asset fallback

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

## 🆕 Recent Updates & Improvements

### 🎯 **Version 2.0.8 - Major Favorites System Overhaul**
*Released: July 2025*

#### 💫 **Enhanced Favorites Management**
- **Collection-Grouped Favorites** - Favorites now organized by song collections for better navigation
- **Visual Collection Cards** - Each collection displays with custom colors and icons
- **Smart Grouping** - Automatic organization of favorite songs by their collections
- **Enhanced Header Design** - Beautiful header with background image and gradient overlay
- **Responsive Layout** - Optimized for all screen sizes with collapsible header
- **Quick Actions** - Refresh and clear all favorites options in header menu

#### 🎨 **Collection Management Enhancements**
- **Color Picker Integration** - Choose from 8 predefined colors for collection customization
- **Icon Selection System** - Pick from 20+ Material Design icons for collections
- **Favorites Toggle** - Enable/disable favorites for specific collections
- **Visual Preview** - Real-time preview of collection appearance
- **Enhanced Admin UI** - Improved collection creation and editing interface

#### 🔧 **Technical Improvements**
- **Repository Pattern** - New `FavoritesRepository` with collection-aware methods
- **State Management** - Improved state handling with proper loading and error states
- **Navigation Updates** - Updated all navigation routes to use new favorites system
- **Performance Optimization** - Efficient data loading and caching
- **Error Handling** - Comprehensive error states with retry mechanisms

#### 🎪 **User Experience Enhancements**
- **Empty State Design** - Beautiful empty states with clear call-to-action buttons
- **Loading States** - Smooth loading animations and progress indicators
- **Success Feedback** - Toast notifications for user actions
- **Intuitive Navigation** - Seamless flow between favorites and song collections
- **Accessibility** - Improved screen reader support and keyboard navigation

#### 🛠️ **Code Quality & Maintenance**
- **Documentation Updates** - Comprehensive inline documentation for new features
- **Test Coverage** - Unit tests for favorites repository and collection services
- **Code Organization** - Clean separation of concerns with repository pattern
- **Firebase Integration** - Optimized Firebase queries for better performance
- **Error Recovery** - Graceful handling of network and database errors

### 📱 **UI/UX Improvements**
- **Consistent Design Language** - Unified header patterns across all pages
- **Material Design 3** - Updated components following latest design guidelines
- **Color Harmony** - Consistent color theming throughout the application
- **Typography** - Improved text hierarchy and readability
- **Interactive Elements** - Enhanced button states and feedback animations

### 🔐 **Security & Reliability**
- **Authentication Flow** - Robust user authentication with proper error handling
- **Data Validation** - Client-side and server-side validation for all user inputs
- **Firebase Rules** - Updated security rules for new collection features
- **Offline Support** - Improved offline functionality for favorites system
- **Backup System** - Automatic backup of user favorites and settings

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

### **✅ Version 2.0.8 - COMPLETED**
- [x] Collection-grouped favorites system
- [x] Enhanced favorites management with visual cards
- [x] Collection color and icon customization
- [x] Improved header design with background images
- [x] Repository pattern implementation
- [x] Enhanced admin collection management
- [x] Comprehensive error handling and loading states

### **🚧 Version 2.1.0 - In Development**
- [x] **Smart Search System** - Intelligent search-first approach replacing "All Songs" for better performance
- [x] **Christmas Collection Debugging** - Advanced diagnostics and automatic fallback for missing collections
- [x] **Enhanced Offline Support** - Improved asset loading and connectivity handling
- [x] **Christmas Collection Protection** - Automatic backup system and deletion prevention for critical collections
- [ ] Audio playback support for hymns
- [ ] Advanced search filters with collection-based filtering
- [ ] Song categories and tagging system
- [ ] Playlist creation and management
- [ ] Improved offline song downloads
- [ ] Enhanced collection sharing features

### **🔮 Version 2.2.0 - Planned**
- [ ] Social features (sharing playlists and collections)
- [ ] Multi-language support (Indonesian, English)
- [ ] Advanced accessibility improvements
- [ ] Performance optimizations for large collections
- [ ] Home screen widget for quick access
- [ ] Collection templates and themes

### **🌟 Future Releases**
- [ ] Web application with responsive design
- [ ] Desktop support (Windows, macOS, Linux)
- [ ] RESTful API for third-party integration
- [ ] Advanced analytics and usage insights
- [ ] Machine learning recommendations
- [ ] Collaborative collection editing
- [ ] Integration with church management systems

## � Changelog

### **Version 2.0.9** - *July 24, 2025*
#### 🎉 **Major Features**
- **NEW**: Smart Search System - Intelligent search-first approach replacing "All Songs"
  - 🔍 Real-time search across 500+ songs by number, title, and lyrics
  - 📊 Quick stats display (total songs, collections, recent additions)
  - 🆕 Recent songs showcase (last 10 added)
  - 🌟 Popular songs highlights (favorited + trending)
  - 📁 Collection previews (top songs from each collection)
  - 🎯 Collection-specific search filtering
  - ✨ Smooth animations and responsive design

- **NEW**: Christmas Collection Diagnostics & Auto-Recovery
  - 🎄 Advanced Christmas collection debugging tools
  - 🔍 Multi-path collection detection (lagu_krismas_26346, christmas, Christmas, etc.)
  - 🛠️ Automatic fallback when collections are missing or empty
  - 📊 Detailed diagnostic reports with recommendations
  - 🔧 Admin-accessible debug interface

- **NEW**: Enhanced Offline Performance
  - ⚡ Improved asset loading with better error handling
  - 📱 Graceful connectivity failure management
  - 💾 Smart caching with automatic fallback to local assets
  - 🔄 Seamless online/offline transitions

- **NEW**: Christmas Collection Protection System
  - 🛡️ Automatic backup creation before dangerous operations
  - 🔍 Deletion investigation and forensic analysis tools
  - ⚠️ Enhanced warning dialogs for operations affecting Christmas collection
  - 🎄 Collection health monitoring and recovery procedures
  - 📊 Backup and restore functionality for critical collections

#### 🔧 **Performance Improvements**
- **OPTIMIZED**: Replaced heavy "All Songs" loading with smart search previews
- **IMPROVED**: Collection loading with dynamic detection and priority handling
- **ENHANCED**: Connectivity checks with detailed logging and fallback mechanisms
- **REDUCED**: Memory usage by loading content on-demand instead of bulk loading
- **FASTER**: Dashboard navigation with targeted content loading

#### 🐛 **Bug Fixes**
- **FIXED**: Christmas collection loading issues with automatic detection
- **FIXED**: Performance bottlenecks in "All Songs" feature (replaced with Smart Search)
- **FIXED**: Connectivity failure handling with proper offline mode
- **FIXED**: Collection detection for missing or renamed collections
- **FIXED**: Memory issues with large song collections
- **SECURITY**: Added protection against accidental Christmas collection deletion
- **PREVENTION**: Enhanced Firebase debug operations with mandatory backup creation
- **NAVIGATION**: Fixed Smart Search page back button navigation issue (blank screen)
- **AUDIO**: Fixed audio playback issues in production builds with enhanced URL handling and permissions

#### 🎨 **UI/UX Enhancements**
- **ENHANCED**: Dashboard navigation with Smart Search integration
- **IMPROVED**: Search interface with collection filtering and real-time results
- **ADDED**: Quick stats cards showing app content overview
- **UPDATED**: Navigation icons from library_music to search for better UX
- **REFINED**: Loading states and error handling throughout the app

#### 🏗️ **Technical Improvements**
- **REFACTORED**: Dashboard sections to use Smart Search instead of "All Songs"
- **ADDED**: Christmas collection debugger with comprehensive path checking
- **IMPROVED**: Song repository with dynamic collection detection
- **ENHANCED**: Error logging and diagnostic capabilities
- **OPTIMIZED**: Asset loading and offline functionality

### **Version 2.0.8** - *July 24, 2025*
#### 🎉 **Major Features**
- **NEW**: Collection-grouped favorites system with visual organization
- **NEW**: Collection customization with colors and icons
- **NEW**: Enhanced header design with background images across all pages
- **NEW**: Repository pattern for better data management

#### 🔧 **Improvements**
- **IMPROVED**: Favorites page now shows collections with custom styling
- **IMPROVED**: Admin collection management with visual customization options
- **IMPROVED**: Navigation consistency across the entire application
- **IMPROVED**: Loading states and error handling throughout the app
- **IMPROVED**: Responsive design for better mobile experience

#### 🐛 **Bug Fixes**
- **FIXED**: Favorites list organization and display issues
- **FIXED**: Collection management missing customization options
- **FIXED**: Header consistency across different pages
- **FIXED**: State management issues in favorites system
- **FIXED**: Navigation flow between favorites and collections

#### 🎨 **UI/UX Enhancements**
- **ENHANCED**: Material Design 3 compliance across components
- **ENHANCED**: Color harmony and visual consistency
- **ENHANCED**: Interactive feedback and animations
- **ENHANCED**: Empty states with clear call-to-action elements
- **ENHANCED**: Accessibility support for screen readers

#### 🏗️ **Technical Improvements**
- **REFACTORED**: Favorites system with repository pattern
- **REFACTORED**: Collection service with enhanced functionality
- **ADDED**: Comprehensive error boundaries and fallbacks
- **ADDED**: Performance optimizations for large collections
- **ADDED**: Unit tests for new repository and service layers

#### 📚 **Documentation**
- **UPDATED**: README with comprehensive feature documentation
- **ADDED**: Inline code documentation for new features
- **ADDED**: API documentation for favorites and collections
- **IMPROVED**: Development setup and contribution guidelines

### **Previous Versions**
For complete version history, see [CHANGELOG.md](CHANGELOG.md)

## �🐛 Bug Reports & Feature Requests

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

- **Songs**: 500+ hymns available across multiple collections
- **Collections**: Organized by themes, seasons, and worship styles
- **Users**: Growing community of worshippers and churches
- **Features**: 25+ core features with regular updates
- **Downloads**: Available on Google Play Store
- **Rating**: ⭐⭐⭐⭐⭐ User-loved (4.8/5.0)
- **Updates**: Monthly feature releases and improvements
- **Languages**: Currently Indonesian, English support in development
- **Platforms**: Android (iOS and Web coming soon)
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