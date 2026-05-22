import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../attachments/domain/attachment_types.dart';
import '../../../../attachments/providers/attachment_providers.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../providers/auth_providers.dart';
import '../../domain/entities/event_entity.dart';
import '../../providers/event_providers.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  final EventEntity? event; // null for create, non-null for edit

  const EventFormScreen({super.key, this.event});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _imagePicker = ImagePicker();

  DateTime _startDateTime = DateTime.now().add(const Duration(days: 1));
  DateTime? _endDateTime;
  EventCategory _selectedCategory = EventCategory.academic;
  bool _isPublished = true;
  bool _isLoading = false;
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _initializeWithEvent(widget.event!);
    }
  }

  void _initializeWithEvent(EventEntity event) {
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _locationController.text = event.location;
    _capacityController.text = event.capacity?.toString() ?? '';
    _currentImageUrl = event.imageUrl;
    _startDateTime = event.startDateTime;
    _endDateTime = event.endDateTime;
    _selectedCategory = event.category;
    _isPublished = event.isPublished;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<String?> _uploadImage(String eventId) async {
    if (_selectedImage == null) return _currentImageUrl;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final attachmentService = ref.read(attachmentServiceProvider);
      final file = File(_selectedImage!.path);
      final draft = await attachmentService.prepareImage(
        owner: AttachmentOwnerRef(
          type: AttachmentOwnerType.event,
          ownerId: eventId,
        ),
        image: AttachmentInput.image(
          bytes: await file.readAsBytes(),
          fileName: _selectedImage!.path.split('/').last,
          mimeType: 'image/jpeg',
          sizeBytes: await file.length(),
        ),
      );
      final imageUrl = draft.metadata.url;

      setState(() {
        _isUploadingImage = false;
      });

      return imageUrl;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
      return _currentImageUrl;
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDateTime : (_endDateTime ?? _startDateTime),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isStart ? _startDateTime : (_endDateTime ?? _startDateTime),
        ),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStart) {
            _startDateTime = dateTime;
            // Reset end date if it's before start date
            if (_endDateTime != null &&
                _endDateTime!.isBefore(_startDateTime)) {
              _endDateTime = null;
            }
          } else {
            _endDateTime = dateTime;
          }
        });
      }
    }
  }

  Future<void> _saveEvent() async {
    if (_isLoading || _isUploadingImage) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final eventId = widget.event?.id ?? const Uuid().v4();

      // Upload image if selected
      final String? imageUrl = await _uploadImage(eventId);

      // If user selected an image but upload didn't produce a URL, abort save
      if (_selectedImage != null && imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image. Please try again.')),
          );
        }
        return;
      }

      final service = ref.read(eventServiceProvider);

      final event = EventEntity(
        id: eventId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        startDateTime: _startDateTime,
        endDateTime: _endDateTime,
        category: _selectedCategory,
        createdAt: widget.event?.createdAt ?? DateTime.now(),
        createdBy: widget.event?.createdBy ?? currentUser.userId,
        createdByName: widget.event?.createdByName ?? currentUser.fullName,
        isPublished: _isPublished,
        attendeeCount: widget.event?.attendeeCount ?? 0,
        capacity: _capacityController.text.trim().isEmpty
            ? null
            : int.tryParse(_capacityController.text.trim()),
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      if (widget.event == null) {
        await service.createEvent(event);
      } else {
        await service.updateEvent(event);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event == null
                  ? 'Event created successfully'
                  : 'Event updated successfully',
            ),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save event: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surface,
      appBar: AppBar(
        title: Text(
          widget.event == null ? 'Create Event' : 'Edit Event',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: DesignTokens.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.spacing16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Event Title *',
                hintText: 'Enter event title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: DesignTokens.spacing16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description *',
                hintText: 'Enter event description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: DesignTokens.spacing16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location *',
                hintText: 'Enter event location',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Location is required';
                }
                return null;
              },
            ),
            const SizedBox(height: DesignTokens.spacing16),

            // Category
            DropdownButtonFormField<EventCategory>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
              ),
              items: EventCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_getCategoryLabel(category)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: DesignTokens.spacing16),

            // Start Date/Time
            ListTile(
              title: Text(
                'Start Date & Time *',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _formatDateTime(_startDateTime),
                style: GoogleFonts.manrope(fontSize: 16),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDateTime(context, true),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                side: BorderSide(color: DesignTokens.outlineVariant),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing16),

            // End Date/Time (Optional)
            ListTile(
              title: Text(
                'End Date & Time (Optional)',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _endDateTime != null
                    ? _formatDateTime(_endDateTime!)
                    : 'Not set',
                style: GoogleFonts.manrope(fontSize: 16),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endDateTime != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _endDateTime = null;
                        });
                      },
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              onTap: () => _selectDateTime(context, false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                side: BorderSide(color: DesignTokens.outlineVariant),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing16),

            // Capacity (Optional)
            TextFormField(
              controller: _capacityController,
              decoration: InputDecoration(
                labelText: 'Capacity (Optional)',
                hintText: 'Enter maximum attendees',
                prefixIcon: const Icon(Icons.people),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                helperText: 'Leave empty for unlimited capacity',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final capacity = int.tryParse(value.trim());
                  if (capacity == null || capacity <= 0) {
                    return 'Capacity must be a positive number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: DesignTokens.spacing16),

            // Event Image (Optional)
            Text(
              'Event Image (Optional)',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: DesignTokens.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: DesignTokens.outlineVariant),
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusMd,
                            ),
                            child: Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _currentImageUrl != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusMd,
                            ),
                            child: Image.network(
                              _currentImageUrl!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: 48,
                                        color: DesignTokens.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Failed to load image',
                                        style: GoogleFonts.manrope(
                                          color: DesignTokens.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentImageUrl = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: DesignTokens.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add event image',
                              style: GoogleFonts.manrope(
                                color: DesignTokens.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing16),

            // Published Switch
            SwitchListTile(
              title: Text(
                'Published',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _isPublished
                    ? 'Event is visible to all users'
                    : 'Event is hidden (draft)',
                style: GoogleFonts.manrope(fontSize: 14),
              ),
              value: _isPublished,
              onChanged: (value) {
                setState(() {
                  _isPublished = value;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                side: BorderSide(color: DesignTokens.outlineVariant),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing24),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || _isUploadingImage)
                    ? null
                    : _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primary,
                  foregroundColor: DesignTokens.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                  ),
                ),
                child: (_isLoading || _isUploadingImage)
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: DesignTokens.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.event == null ? 'Create Event' : 'Update Event',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return 'Academic';
      case EventCategory.social:
        return 'Social';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.career:
        return 'Career';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
