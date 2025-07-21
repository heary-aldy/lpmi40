// lib/src/features/settings/presentation/widgets/settings_widgets.dart
// ✅ NEW: Reusable widget components for settings

import 'package:flutter/material.dart';
import 'package:lpmi40/utils/constants.dart';

// ✅ SETTINGS GROUP WRAPPER
class SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final DeviceType deviceType;

  const SettingsGroup({
    super.key,
    required this.title,
    required this.children,
    required this.deviceType,
  });

  @override
  Widget build(BuildContext context) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: spacing * 0.75),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ✅ SETTINGS ROW (Tappable)
class SettingsRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final DeviceType deviceType;
  final Widget? trailing;

  const SettingsRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.deviceType,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return ListTile(
      leading: Icon(
        icon,
        size: 24 * scale,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16 * scale,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14 * scale,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            size: 20 * scale,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
          ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacing,
        vertical: spacing * 0.25,
      ),
    );
  }
}

// ✅ SETTINGS TILE (With custom trailing widget)
class SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;
  final DeviceType deviceType;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
    required this.deviceType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return ListTile(
      leading: Icon(
        icon,
        size: 24 * scale,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16 * scale,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14 * scale,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacing,
        vertical: spacing * 0.25,
      ),
    );
  }
}

// ✅ SETTINGS DIVIDER
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor.withOpacity(0.3),
    );
  }
}

// ✅ LOADING SECTION
class LoadingSection extends StatelessWidget {
  final String title;
  final DeviceType deviceType;

  const LoadingSection({
    super.key,
    required this.title,
    required this.deviceType,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      title: title,
      deviceType: deviceType,
      children: [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ✅ ERROR SECTION
class ErrorSection extends StatelessWidget {
  final String title;
  final String errorMessage;
  final VoidCallback onRetry;
  final DeviceType deviceType;

  const ErrorSection({
    super.key,
    required this.title,
    required this.errorMessage,
    required this.onRetry,
    required this.deviceType,
  });

  @override
  Widget build(BuildContext context) {
    final scale = AppConstants.getTypographyScale(deviceType);

    return SettingsGroup(
      title: title,
      deviceType: deviceType,
      children: [
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48 * scale,
                color: Colors.red,
              ),
              SizedBox(height: 16 * scale),
              Text(
                'Error Loading $title',
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8 * scale),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              SizedBox(height: 16 * scale),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ✅ FEATURE CARD (For premium features, etc.)
class FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;
  final Widget? actionButton;
  final DeviceType deviceType;

  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
    required this.deviceType,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Container(
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24 * scale),
              SizedBox(width: spacing * 0.5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing * 0.75),
          Text(
            description,
            style: TextStyle(
              fontSize: 14 * scale,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          if (features.isNotEmpty) ...[
            SizedBox(height: spacing * 0.5),
            ...features.map((feature) => Padding(
                  padding: EdgeInsets.only(bottom: spacing * 0.25),
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontSize: 13 * scale,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                )),
          ],
          if (actionButton != null) ...[
            SizedBox(height: spacing),
            actionButton!,
          ],
        ],
      ),
    );
  }
}

// ✅ VERSION INFO WIDGET
class VersionInfoWidget extends StatelessWidget {
  final String version;
  final String buildNumber;
  final bool isCheckingUpdates;
  final VoidCallback onCheckUpdates;
  final DeviceType deviceType;

  const VersionInfoWidget({
    super.key,
    required this.version,
    required this.buildNumber,
    required this.isCheckingUpdates,
    required this.onCheckUpdates,
    required this.deviceType,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      title: 'App Version',
      subtitle: isCheckingUpdates
          ? 'Checking for updates...'
          : '$version ($buildNumber)',
      icon: Icons.info,
      deviceType: deviceType,
      onTap: onCheckUpdates,
      trailing: isCheckingUpdates
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }
}

// ✅ ACTION BUTTON
class SettingsActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback onPressed;
  final bool isLoading;
  final DeviceType deviceType;

  const SettingsActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.deviceType,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: EdgeInsets.symmetric(vertical: 12 * scale),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: isLoading
            ? SizedBox(
                width: 18 * scale,
                height: 18 * scale,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18 * scale),
        label: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14 * scale,
          ),
        ),
      ),
    );
  }
}

// ✅ COMPACT INFO ROW
class CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final DeviceType deviceType;

  const CompactInfoRow({
    super.key,
    required this.icon,
    required this.text,
    required this.deviceType,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Padding(
      padding: EdgeInsets.only(bottom: spacing * 0.25),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16 * scale,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: spacing * 0.5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13 * scale,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
