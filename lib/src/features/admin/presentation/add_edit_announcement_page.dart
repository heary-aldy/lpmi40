// lib/src/features/admin/presentation/add_edit_announcement_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lpmi40/src/widgets/admin_header.dart';
import 'package:lpmi40/src/core/services/announcement_service.dart';
import 'package:lpmi40/src/features/announcements/models/announcement_model.dart';
import 'package:lpmi40/src/features/admin/presentation/widgets/announcement_customization_widgets.dart';
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';

class AddEditAnnouncementPage extends StatefulWidget {
  final Announcement? announcementToEdit;
  const AddEditAnnouncementPage({super.key, this.announcementToEdit});

  @override
  State<AddEditAnnouncementPage> createState() =>
      _AddEditAnnouncementPageState();
}

class _AddEditAnnouncementPageState extends State<AddEditAnnouncementPage> {
  final AnnouncementService _announcementService = AnnouncementService();
  final ImagePicker _imagePicker = ImagePicker();

  bool get _isEditing => widget.announcementToEdit != null;
  bool _isLoading = false;

  // Form fields
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'text';
  File? _selectedImage;
  String? _existingImageUrl;
  int _priority = 1;
  DateTime? _expiresAt;

  // Customization state variables
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
    if (_isEditing) {
      _loadAnnouncementData();
    }
  }

  void _loadAnnouncementData() {
    final announcement = widget.announcementToEdit!;
    _titleController.text = announcement.title;
    _contentController.text = announcement.content;
    _selectedType = announcement.type;
    _priority = announcement.priority;
    _expiresAt = announcement.expiresAt;
    _existingImageUrl = announcement.imageUrl;

    // Load customization data
    _selectedTextColor = announcement.textColor;
    _selectedBackgroundColor = announcement.backgroundColor;
    _selectedBackgroundGradient = announcement.backgroundGradient;
    _selectedTextStyle = announcement.textStyle;
    _selectedFontSize = announcement.fontSize;
    _selectedIcon = announcement.selectedIcon;
    _selectedIconColor = announcement.iconColor;

    // If there are custom styles, show the section by default
    if (_selectedTextColor != null ||
        _selectedBackgroundColor != null ||
        _selectedBackgroundGradient != null ||
        _selectedIcon != null) {
      _showCustomization = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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

  Future<void> _saveAnnouncement() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorMessage('Please enter a title');
      return;
    }

    if (_selectedType == 'text' && _contentController.text.trim().isEmpty) {
      _showErrorMessage('Please enter content for text announcement');
      return;
    }

    if (_selectedType == 'image' && _selectedImage == null && !_isEditing) {
      _showErrorMessage('Please select an image for a new image announcement');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;

      final announcement = Announcement(
        id: _isEditing ? widget.announcementToEdit!.id : '',
        title: _titleController.text.trim(),
        content: _selectedType == 'text' ? _contentController.text.trim() : '',
        type: _selectedType,
        imageUrl: _isEditing ? widget.announcementToEdit!.imageUrl : '',
        isActive: _isEditing ? widget.announcementToEdit!.isActive : true,
        priority: _priority,
        createdAt:
            _isEditing ? widget.announcementToEdit!.createdAt : DateTime.now(),
        createdBy: _isEditing
            ? widget.announcementToEdit!.createdBy
            : currentUser.email ?? 'Unknown',
        expiresAt: _expiresAt,
        textColor: _selectedTextColor,
        backgroundColor: _selectedBackgroundColor,
        backgroundGradient: _selectedBackgroundGradient,
        textStyle: _selectedTextStyle,
        fontSize: _selectedFontSize,
        selectedIcon: _selectedIcon,
        iconColor: _selectedIconColor,
      );

      if (_isEditing) {
        await _announcementService.updateAnnouncement(
            announcement, _selectedImage);
      } else {
        await _announcementService.createAnnouncement(
            announcement, _selectedImage);
      }

      if (mounted) {
        _showSuccessMessage(
            'Announcement ${_isEditing ? 'updated' : 'created'} successfully!');
        Navigator.of(context).pop(true); // Return true to signal a refresh
      }
    } catch (e) {
      _showErrorMessage('Failed to save announcement: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    AdminHeader(
                      title: _isEditing
                          ? 'Edit Announcement'
                          : 'Create Announcement',
                      subtitle: 'Fill in the details below',
                      icon: _isEditing ? Icons.edit : Icons.add_circle,
                      primaryColor: Colors.teal,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                      if (_selectedType == 'image') {
                                        _contentController.clear();
                                      } else {
                                        _selectedImage = null;
                                      }
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
                              _buildImagePicker(),
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
                                        items: List.generate(
                                                10, (index) => index + 1)
                                            .map((value) => DropdownMenuItem(
                                                value: value,
                                                child: Text(value.toString())))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(
                                              () => _priority = value ?? 1);
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
                                          DateTime.now()
                                              .add(const Duration(days: 30)),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setState(() => _expiresAt = date);
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
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveAnnouncement,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.save),
                              label: Text(
                                  _isLoading ? 'Saving...' : 'Save Changes'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 8,
                  child: const BackButton(color: Colors.white),
                ),
              ],
            ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 150),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : (_existingImageUrl != null &&
                            _existingImageUrl!.isNotEmpty)
                        ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                        : const Center(child: Text('No Image')),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Change'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedStylingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showCustomization = !_showCustomization),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(_showCustomization ? Icons.expand_less : Icons.expand_more,
                    color: Colors.teal),
                const SizedBox(width: 8),
                const Text('Advanced Styling',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal)),
                const Spacer(),
                if (_showCustomization)
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedTextColor = null;
                      _selectedBackgroundColor = null;
                      _selectedBackgroundGradient = null;
                      _selectedTextStyle = null;
                      _selectedFontSize = null;
                      _selectedIcon = null;
                      _selectedIconColor = null;
                    }),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
        ),
        if (_showCustomization)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                IconPickerWidget(
                  selectedIcon: _selectedIcon,
                  onIconSelected: (icon) =>
                      setState(() => _selectedIcon = icon),
                ),
                const SizedBox(height: 16),
                ColorPickerWidget(
                  title: 'Icon Color',
                  colors: AnnouncementTheme.textColors,
                  selectedColor: _selectedIconColor,
                  onColorSelected: (color) =>
                      setState(() => _selectedIconColor = color),
                ),
                const SizedBox(height: 16),
                ColorPickerWidget(
                  title: 'Text Color',
                  colors: AnnouncementTheme.textColors,
                  selectedColor: _selectedTextColor,
                  onColorSelected: (color) =>
                      setState(() => _selectedTextColor = color),
                ),
                const SizedBox(height: 16),
                GradientPickerWidget(
                  selectedGradient: _selectedBackgroundGradient,
                  onGradientSelected: (gradient) => setState(() {
                    _selectedBackgroundGradient = gradient;
                    _selectedBackgroundColor = null;
                  }),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
