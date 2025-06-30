// ✅ COMPLETE USER PERMISSIONS BREAKDOWN

/*
=============================================================================
👤 REGULAR USERS (Authenticated with email/password)
=============================================================================
✅ CAN DO:
- Browse all songs
- Search songs by number/title
- View song lyrics
- Add/remove favorites (synced to Firebase)
- Access favorites list
- View "Verse of the Day"
- Change app settings (theme, text size, etc.)
- Share songs
- Access "More From Us" apps
- Sign out

❌ CANNOT DO:
- Add new songs
- Edit songs
- Delete songs
- Access admin management
- Access user management
- Access Firebase debugging
- Grant admin roles to others

💾 Favorites Storage: Firebase (synced across devices)
*/

/*
=============================================================================
👻 GUEST USERS (Anonymous authentication)
=============================================================================
✅ CAN DO:
- Browse all songs
- Search songs by number/title
- View song lyrics
- Add/remove favorites (stored locally)
- Access favorites list
- View "Verse of the Day"
- Change app settings (theme, text size, etc.)
- Share songs
- Access "More From Us" apps
- Upgrade to full account later (with favorite migration)

❌ CANNOT DO:
- Sync favorites across devices
- Add new songs
- Edit songs
- Delete songs
- Access any admin features

💾 Favorites Storage: Local device only (SharedPreferences)
*/

/*
=============================================================================
🛂 NO AUTHENTICATION (Skipped login entirely)
=============================================================================
✅ CAN DO:
- Browse all songs
- Search songs by number/title
- View song lyrics
- Add/remove favorites (stored locally)
- Access favorites list
- View "Verse of the Day"
- Change app settings (theme, text size, etc.)
- Share songs
- Access "More From Us" apps

❌ CANNOT DO:
- Sync favorites across devices
- Add new songs
- Edit songs
- Delete songs
- Access any admin features

💾 Favorites Storage: Local device only (SharedPreferences)
*/

/*
=============================================================================
🔧 ADMIN USERS (Verified admin role)
=============================================================================
✅ CAN DO (All regular user features PLUS):
- Add new songs
- Edit existing songs
- Delete songs
- Access song management dashboard
- View admin status in dashboard
- Access Firebase debugging (if super admin)

❌ CANNOT DO:
- Manage other users (super admin only)
- Grant/revoke admin roles to others
- Access super admin features

💾 Favorites Storage: Firebase (synced across devices)
🎯 Admin Badge: Orange "ADMIN" badge in header
*/

/*
=============================================================================
🛡️ SUPER ADMIN USERS (Hardcoded email list)
=============================================================================
✅ CAN DO (All admin features PLUS):
- Manage all users
- Grant/revoke admin roles
- Grant/revoke super admin roles (to eligible emails only)
- Access Firebase debugging tools
- Full system administration

❌ CANNOT DO:
- Grant super admin to non-eligible emails
- Revoke super admin from other super admins

💾 Favorites Storage: Firebase (synced across devices)
🎯 Admin Badge: Red "SUPER ADMIN" badge in header
📧 Eligible Emails: heary_aldy@hotmail.com, heary@hopetv.asia, admin@lpmi.com, admin@haweeinc.com
*/

/*
=============================================================================
🔄 AUTHENTICATION FLOWS
=============================================================================

1. EMAIL/PASSWORD SIGN UP:
   - Creates Firebase user account
   - Assigns "user" role by default
   - Favorites synced to Firebase
   - Can use app fully (except admin features)

2. EMAIL/PASSWORD SIGN IN:
   - Authenticates existing user
   - Loads user role from Firebase
   - Favorites synced to Firebase
   - Access based on assigned role

3. GUEST/ANONYMOUS:
   - Creates anonymous Firebase user
   - No role assignment needed
   - Favorites stored locally
   - Can upgrade to full account later

4. SKIP AUTHENTICATION:
   - No Firebase authentication
   - No user account created
   - Favorites stored locally only
   - Full song browsing available

=============================================================================
*/
