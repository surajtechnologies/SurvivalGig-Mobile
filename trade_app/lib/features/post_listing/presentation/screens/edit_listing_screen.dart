import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/domain/entities/listing.dart';
import '../cubit/edit_listing_cubit.dart';
import '../cubit/edit_listing_state.dart';
import 'listing_location_picker_screen.dart';

/// Screen for editing every field supported by the update-listing API.
class EditListingScreen extends StatelessWidget {
  final Listing listing;

  const EditListingScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EditListingCubit>(),
      child: _EditListingView(listing: listing),
    );
  }
}

class _EditListingView extends StatefulWidget {
  final Listing listing;

  const _EditListingView({required this.listing});

  @override
  State<_EditListingView> createState() => _EditListingViewState();
}

class _EditListingViewState extends State<_EditListingView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _pointsController;
  late List<ListingPhoto> _remainingPhotos;
  final Set<String> _deletedPhotoIds = {};
  String? _urgencyLevel;
  DateTime? _expiresAt;
  double? _latitude;
  double? _longitude;

  bool get _requiresPoints {
    final mode = widget.listing.priceMode.toUpperCase();
    return mode == 'POINTS' || mode == 'BOTH';
  }

  bool get _hasValidCoordinates =>
      _latitude != null &&
      _longitude != null &&
      _latitude! >= -90 &&
      _latitude! <= 90 &&
      _longitude! >= -180 &&
      _longitude! <= 180;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.listing.title);
    _descriptionController = TextEditingController(
      text: widget.listing.description ?? '',
    );
    _pointsController = TextEditingController(
      text: widget.listing.pricePoints?.toString() ?? '',
    );
    _remainingPhotos = [...widget.listing.photos];
    _urgencyLevel = widget.listing.urgencyLevel;
    _expiresAt = widget.listing.expiresAt;
    _latitude = widget.listing.latitude;
    _longitude = widget.listing.longitude;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final pointsText = _pointsController.text.trim();
    context.read<EditListingCubit>().updateListing(
      listingId: widget.listing.id,
      title: _titleController.text.trim(),
      pricePoints: pointsText.isEmpty ? null : int.parse(pointsText),
      description: _descriptionController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      urgencyLevel: _urgencyLevel,
      expiresAt: _expiresAt,
      deletePhotoIds: _deletedPhotoIds.toList(),
    );
  }

  void _removePhoto(ListingPhoto photo) {
    if (photo.id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This photo cannot be removed because its ID is missing',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final removedIndex = _remainingPhotos.indexOf(photo);
    setState(() {
      _remainingPhotos.remove(photo);
      _deletedPhotoIds.add(photo.id);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Photo will be deleted when you save'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              if (!mounted) return;
              setState(() {
                final index = removedIndex.clamp(0, _remainingPhotos.length);
                _remainingPhotos.insert(index, photo);
                _deletedPhotoIds.remove(photo.id);
              });
            },
          ),
        ),
      );
  }

  Future<void> _selectLocation() async {
    if (!_hasValidCoordinates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This listing has no valid latitude and longitude to edit.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final initialTarget = LatLng(_latitude!, _longitude!);
    final selected = await Navigator.push<PickedListingLocation>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ListingLocationPickerScreen(initialTarget: initialTarget),
      ),
    );

    if (selected == null || !mounted) return;
    setState(() {
      _latitude = selected.latitude;
      _longitude = selected.longitude;
    });
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentDate = _expiresAt == null
        ? null
        : DateTime(_expiresAt!.year, _expiresAt!.month, _expiresAt!.day);
    final initialDate = currentDate != null && !currentDate.isBefore(today)
        ? currentDate
        : today.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
    );

    if (picked == null || !mounted) return;
    setState(() => _expiresAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditListingCubit, EditListingState>(
      listener: (context, state) {
        if (state is EditListingSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
        if (state is EditListingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is EditListingSubmitting;

        return Scaffold(
          backgroundColor: AppColors.dashboardBackground,
          appBar: AppBar(
            backgroundColor: AppColors.dashboardBackground,
            surfaceTintColor: AppColors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Edit Listing',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(false),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Post Title'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _titleController,
                    hint: 'Enter your post title',
                    maxLength: 100,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPhotosSection(),
                  const SizedBox(height: 20),
                  _buildFieldLabel(
                    _requiresPoints
                        ? 'Price Points'
                        : 'Price Points (Optional)',
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _pointsController,
                    hint: 'Enter price in points',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty && _requiresPoints) {
                        return 'Price points is required';
                      }
                      if (text.isNotEmpty &&
                          (int.tryParse(text) == null ||
                              int.parse(text) <= 0)) {
                        return 'Enter a valid price greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildLocationSection(),
                  const SizedBox(height: 20),
                  _buildFieldLabel('Description'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _descriptionController,
                    hint: 'Describe your post in detail',
                    maxLines: 4,
                    maxLength: 250,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildUrgencyDropdown(),
                  const SizedBox(height: 20),
                  _buildExpiryDatePicker(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () => _submit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isSubmitting ? 'Saving...' : 'Save Changes',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Photos'),
        const SizedBox(height: 8),
        if (_remainingPhotos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.dashboardSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dashboardBorder),
            ),
            child: Text(
              'No photos will remain after saving.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOnDarkSecondary,
              ),
            ),
          )
        else
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _remainingPhotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final photo = _remainingPhotos[index];
                return SizedBox(
                  width: 112,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: photo.url,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Container(
                              color: AppColors.dashboardSurfaceElevated,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.textOnDarkSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: AppColors.dashboardBackground.withValues(
                            alpha: 0.85,
                          ),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _removePhoto(photo),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (_deletedPhotoIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${_deletedPhotoIds.length} photo(s) marked for deletion',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSection() {
    final hasCoordinates = _hasValidCoordinates;
    final locationLabel = widget.listing.location?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Location'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.dashboardSurfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasCoordinates
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.dashboardBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasCoordinates ? Icons.location_on : Icons.location_searching,
                color: hasCoordinates
                    ? AppColors.primary
                    : AppColors.textOnDarkSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationLabel == null || locationLabel.isEmpty
                          ? 'Listing location'
                          : locationLabel,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textOnDarkPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCoordinates
                          ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                          : 'Select a location on the map',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnDarkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _selectLocation,
            icon: const Icon(Icons.map_rounded, size: 18),
            label: const Text('Select from Map'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.45),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUrgencyDropdown() {
    const levels = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Urgency Level'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _urgencyLevel,
          dropdownColor: AppColors.dashboardSurfaceElevated,
          decoration: _inputDecoration(),
          hint: const Text('Select urgency'),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('None')),
            ...levels.map(
              (level) =>
                  DropdownMenuItem<String>(value: level, child: Text(level)),
            ),
          ],
          onChanged: (value) => setState(() => _urgencyLevel = value),
        ),
      ],
    );
  }

  Widget _buildExpiryDatePicker() {
    final dateLabel = _expiresAt == null
        ? 'Select expiry date'
        : '${_expiresAt!.year.toString().padLeft(4, '0')}-'
              '${_expiresAt!.month.toString().padLeft(2, '0')}-'
              '${_expiresAt!.day.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Expiry Date'),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _selectExpiryDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.dashboardSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dashboardBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.textOnDarkSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dateLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _expiresAt == null
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textOnDarkPrimary,
                    ),
                  ),
                ),
                if (_expiresAt != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Clear expiry date',
                    onPressed: () => setState(() => _expiresAt = null),
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textOnDarkPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textOnDarkSecondary,
      ),
      filled: true,
      fillColor: AppColors.dashboardSurfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.dashboardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.dashboardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textOnDarkPrimary,
      ),
      decoration: _inputDecoration(hint: hint).copyWith(
        counterStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textOnDarkSecondary,
        ),
      ),
    );
  }
}
