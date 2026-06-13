import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

const defaultListingLocation = LatLng(37.7749, -122.4194);

const _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#17231d"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8fa19a"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#07100d"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#2b3a33"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#7c8f86"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#0f3a2c"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#293832"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#111b16"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#344a40"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#213129"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0b1a20"}]}
]
''';

class PickedListingLocation {
  final double latitude;
  final double longitude;

  const PickedListingLocation({
    required this.latitude,
    required this.longitude,
  });
}

class ListingLocationPickerScreen extends StatefulWidget {
  final LatLng initialTarget;

  const ListingLocationPickerScreen({super.key, required this.initialTarget});

  @override
  State<ListingLocationPickerScreen> createState() =>
      _ListingLocationPickerScreenState();
}

class _ListingLocationPickerScreenState
    extends State<ListingLocationPickerScreen> {
  late LatLng _selectedLocation;
  late final ValueNotifier<LatLng> _locationNotifier;
  GoogleMapController? _googleMapController;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialTarget;
    _locationNotifier = ValueNotifier<LatLng>(_selectedLocation);
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    _locationNotifier.dispose();
    super.dispose();
  }

  void _updateGoogleCamera(CameraPosition position) {
    _selectedLocation = position.target;
    _locationNotifier.value = _selectedLocation;
  }

  Future<void> _onGoogleCameraIdle() async {
    final bounds = await _googleMapController?.getVisibleRegion();
    if (bounds == null) return;
    final center = LatLng(
      (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
      (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
    );
    _selectedLocation = center;
    _locationNotifier.value = center;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.dashboardBackground,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textOnDarkPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Location',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textOnDarkPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -18),
                child: Icon(
                  Icons.location_pin,
                  color: AppColors.primary,
                  size: 52,
                  shadows: [
                    Shadow(
                      color: AppColors.black.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.initialTarget,
        zoom: 15,
      ),
      onMapCreated: (controller) => _googleMapController = controller,
      onCameraMove: _updateGoogleCamera,
      onCameraIdle: _onGoogleCameraIdle,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
      mapType: MapType.normal,
      style: _darkMapStyle,
    );
  }

  Widget _buildBottomPanel() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.dashboardSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dashboardBorder),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<LatLng>(
                valueListenable: _locationNotifier,
                builder: (context, location, child) {
                  return Text(
                    '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textOnDarkPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    PickedListingLocation(
                      latitude: _selectedLocation.latitude,
                      longitude: _selectedLocation.longitude,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Confirm Location',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
