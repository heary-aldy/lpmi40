// lib/src/features/admin/presentation/announcement_management_page.dart
// ✅ FINAL FIX: Restored the "Create Announcement" card to the page.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lpmi40/src/widgets/admin_header.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';
import 'package:lpmi40/src/core/services/announcement_service.dart';
import 'package:lpmi40/src/features/announcements/models/announcement_model.dart';
import 'package:lpmi40/src/features/admin/presentation/widgets/announcement_customization_widgets.dart';
import 'package:lpmi40/src/features/admin/presentation/add_edit_announcement_page.dart';
import 'package:lpmi40/src/features/dashboard/presentation/revamped_dashboard_page.dart';

class AnnouncementManagementPage extends StatefulWidget {
  const AnnouncementManagementPage({super.key});

  @override
  State<AnnouncementManagementPage> createState() =>
      _AnnouncementManagementPageState();
}

class _AnnouncementManagementPageState
    extends State<AnnouncementManagementPage> {
  final AuthorizationService _authService = AuthorizationService();
  final AnnouncementService _announcementService = AnnouncementService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isAuthorized = false;
  bool _isCheckingAuth = true;
  bool _isCreating = false;

  List<Announcement> _announcements = [];
  String _sortOrder = 'priority';

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'text';
  File? _selectedImage;
  int _priority = 1;
  DateTime? _expiresAt;

  bool _showCustomization = false;
  String? _selectedTextColor;
  String? _selectedBackgroundColor;
  String? _selectedBackgroundGradient;
  String? _selectedTextStyle;
  double? _selectedFontSize;
  String? _selectedIcon;
  String? _selectedIconColor;

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthorization() async {
    try {
      final result = await _authService.checkUserRole(UserRole.superAdmin);
      if (mounted) {
        setState(() {
          _isAuthorized = result.isAuthorized;
          _isCheckingAuth = false;
        });
        if (_isAuthorized) {
          await _loadAnnouncements();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthorized = false;
          _isCheckingAuth = false;
        });
        _showErrorMessage('Authorization check failed: $e');
      }
    }
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final announcements = await _announcementService.getAllAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = _sortAnnouncements(announcements);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage('Failed to load announcements: $e');
      }
    }
  }

  List<Announcement> _sortAnnouncements(List<Announcement> announcements) {
    switch (_sortOrder) {
      case 'priority':
        return announcements..sort((a, b) => a.priority.compareTo(b.priority));
      case 'created':
        return announcements
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'title':
        return announcements..sort((a, b) => a.title.compareTo(b.title));
      default:
        return announcements;
    }
  }

  void _changeSortOrder() {
    final orders = ['priority', 'created', 'title'];
    final currentIndex = orders.indexOf(_sortOrder);
    final nextIndex = (currentIndex + 1) % orders.length;
    setState(() {
      _sortOrder = orders[nextIndex];
      _announcements = _sortAnnouncements(_announcements);
    });
  }

  Future<void> _createAnnouncement() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorMessage('Please enter a title');
      return;
    }
    if (_selectedType == 'text' && _contentController.text.trim().isEmpty) {
      _showErrorMessage('Please enter content for text announcement');
      return;
    }
    if (_selectedType == 'image' && _selectedImage == null) {
      _showErrorMessage('Please select an image for image announcement');
      return;
    }
    setState(() => _isCreating = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final announcement = Announcement(
        id: '',
        title: _titleController.text.trim(),
        content: _selectedType == 'text' ? _contentController.text.trim() : '',
        type: _selectedType,
        imageUrl: '',
        isActive: true,
        priority: _priority,
        createdAt: DateTime.now(),
        createdBy: currentUser.email ?? 'Unknown',
        expiresAt: _expiresAt,
        textColor: _selectedTextColor,
        backgroundColor: _selectedBackgroundColor,
        backgroundGradient: _selectedBackgroundGradient,
        textStyle: _selectedTextStyle,
        fontSize: _selectedFontSize,
        selectedIcon: _selectedIcon,
        iconColor: _selectedIconColor,
      );

      await _announcementService.createAnnouncement(
          announcement, _selectedImage);
      _resetForm();
      await _loadAnnouncements();
      _showSuccessMessage('Announcement created successfully!');
    } catch (e) {
      _showErrorMessage('Failed to create announcement: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _selectedType = 'text';
      _selectedImage = null;
      _priority = 1;
      _expiresAt = null;
      _selectedTextColor = null;
      _selectedBackgroundColor = null;
      _selectedBackgroundGradient = null;
      _selectedTextStyle = null;
      _selectedFontSize = null;
      _selectedIcon = null;
      _selectedIconColor = null;
      _showCustomization = false;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 450,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image: $e');
    }
  }

  Future<void> _navigateToEditPage(Announcement announcement) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            AddEditAnnouncementPage(announcementToEdit: announcement),
      ),
    );
    if (result == true && mounted) {
      _loadAnnouncements();
    }
  }

  Future<void> _toggleAnnouncementStatus(Announcement announcement) async {
    try {
      await _announcementService.toggleAnnouncementStatus(
          announcement.id, !announcement.isActive);
      await _loadAnnouncements();
      _showSuccessMessage(announcement.isActive
          ? 'Announcement deactivated'
          : 'Announcement activated');
    } catch (e) {
      _showErrorMessage('Failed to update announcement: $e');
    }
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this announcement?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                announcement.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _announcementService.deleteAnnouncement(announcement.id);
        await _loadAnnouncements();
        _showSuccessMessage('Announcement deleted successfully');
      } catch (e) {
        _showErrorMessage('Failed to delete announcement: $e');
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error,
              color: Theme.of(context).colorScheme.onError,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        appBar: AppBar(title: const Text('Announcements Management')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Announcements Management')),
        body: const Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              AdminHeader(
                title: 'Announcements Management',
                subtitle:
                    'Manage news & banners - Sort: ${_sortOrder.toUpperCase()}',
                icon: Icons.campaign,
                primaryColor: Colors.indigo,
                actions: [
                  IconButton(
                    icon: Icon(_sortOrder == 'priority'
                        ? Icons.low_priority
                        : _sortOrder == 'created'
                            ? Icons.access_time
                            : Icons.sort_by_alpha),
                    tooltip: 'Change sort order',
                    onPressed: _changeSortOrder,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: _loadAnnouncements,
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ FIXED: The create announcement card is back.
                      _buildCreateAnnouncementCard(),
                      const SizedBox(height: 24),
                      _buildAnnouncementsHeader(),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_announcements.isEmpty)
                        _buildEmptyState()
                      else
                        _buildAnnouncementsList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ✅ RESPONSIVE FIX: Back button only shows on mobile devices to avoid double back buttons
          if (MediaQuery.of(context).size.width < 768.0)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 8,
              child: BackButton(
                color: Theme.of(context).colorScheme.onPrimary,
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const RevampedDashboardPage()),
                  (route) => false,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateAnnouncementCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.add_circle, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Create New Announcement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Type: '),
                const SizedBox(width: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'text',
                        label: Text('Text'),
                        icon: Icon(Icons.text_fields)),
                    ButtonSegment(
                        value: 'image',
                        label: Text('Image'),
                        icon: Icon(Icons.image)),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _selectedType = selection.first;
                      _selectedImage = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedType == 'text') ...[
              TextField(
                controller: _contentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_selectedType == 'image') ...[
              Container(
                constraints: const BoxConstraints(
                  minHeight: 100,
                  maxHeight: 120,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('No image selected'),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pick Image'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text('Priority: '),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _priority,
                        items: List.generate(10, (index) => index + 1)
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.toString()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _priority = value ?? 1;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _expiresAt ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _expiresAt = date;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_expiresAt != null
                      ? 'Expires: ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                      : 'Set Expiration'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAdvancedStylingSection(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isCreating ? null : _createAnnouncement,
              icon: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_isCreating ? 'Creating...' : 'Create Announcement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedStylingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showCustomization = !_showCustomization;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.indigo.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  _showCustomization ? Icons.expand_less : Icons.expand_more,
                  color: Colors.indigo,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Advanced Styling',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
                const Spacer(),
                if (_showCustomization)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedTextColor = null;
                        _selectedBackgroundColor = null;
                        _selectedBackgroundGradient = null;
                        _selectedTextStyle = null;
                        _selectedFontSize = null;
                        _selectedIcon = null;
                        _selectedIconColor = null;
                      });
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_showCustomization) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconPickerWidget(
                  selectedIcon: _selectedIcon,
                  onIconSelected: (icon) {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ColorPickerWidget(
                  title: 'Icon Color',
                  colors: AnnouncementTheme.textColors,
                  selectedColor: _selectedIconColor,
                  onColorSelected: (color) {
                    setState(() {
                      _selectedIconColor = color;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ColorPickerWidget(
                  title: 'Text Color',
                  colors: AnnouncementTheme.textColors,
                  selectedColor: _selectedTextColor,
                  onColorSelected: (color) {
                    setState(() {
                      _selectedTextColor = color;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ColorPickerWidget(
                  title: 'Background Color',
                  colors: AnnouncementTheme.backgroundColors,
                  selectedColor: _selectedBackgroundColor,
                  onColorSelected: (color) {
                    setState(() {
                      _selectedBackgroundColor = color;
                      _selectedBackgroundGradient = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                GradientPickerWidget(
                  selectedGradient: _selectedBackgroundGradient,
                  onGradientSelected: (gradient) {
                    setState(() {
                      _selectedBackgroundGradient = gradient;
                      _selectedBackgroundColor = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextStylePickerWidget(
                  selectedTextStyle: _selectedTextStyle,
                  onTextStyleSelected: (style) {
                    setState(() {
                      _selectedTextStyle = style;
                    });
                  },
                ),
                const SizedBox(height: 16),
                FontSizeSliderWidget(
                  fontSize: _selectedFontSize,
                  onFontSizeChanged: (size) {
                    setState(() {
                      _selectedFontSize = size;
                    });
                  },
                ),
                const SizedBox(height: 16),
                AnnouncementPreviewWidget(
                  title: _titleController.text,
                  content: _contentController.text,
                  selectedIcon: _selectedIcon,
                  iconColor: _selectedIconColor,
                  textColor: _selectedTextColor,
                  backgroundColor: _selectedBackgroundColor,
                  backgroundGradient: _selectedBackgroundGradient,
                  textStyle: _selectedTextStyle,
                  fontSize: _selectedFontSize,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnnouncementsHeader() {
    return Row(
      children: [
        const Icon(Icons.list, color: Colors.indigo),
        const SizedBox(width: 8),
        const Text(
          'Current Announcements',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_announcements.length} total',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No announcements yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first announcement to get started',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return Column(
      children: _announcements.map((announcement) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      announcement.type == 'image'
                          ? Icons.image
                          : Icons.text_fields,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (announcement.selectedIcon != null ||
                        announcement.textColor != null ||
                        announcement.backgroundColor != null ||
                        announcement.backgroundGradient != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.palette, size: 12, color: Colors.purple),
                            const SizedBox(width: 4),
                            Text('STYLED',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple)),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            announcement.isActive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        announcement.isActive ? 'ACTIVE' : 'INACTIVE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (announcement.content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    announcement.content,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.priority_high,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Priority: ${announcement.priority}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Text(
                      '${announcement.createdAt.day}/${announcement.createdAt.month}/${announcement.createdAt.year}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToEditPage(announcement),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _toggleAnnouncementStatus(announcement),
                        icon: Icon(
                            announcement.isActive
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 16),
                        label: Text(
                            announcement.isActive ? 'Deactivate' : 'Activate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: announcement.isActive
                              ? Colors.orange
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
