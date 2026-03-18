import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../config/env/app_config.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../listing_detail/presentation/screens/my_listings_screen.dart';
import 'my_ratings_screen.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_info_tile.dart';
import '../widgets/profile_section_header.dart';

/// Profile settings screen
class ProfileScreen extends StatelessWidget {
  final VoidCallback? onBackTap;
  final VoidCallback? onLogoutTap;

  const ProfileScreen({super.key, this.onBackTap, this.onLogoutTap});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileCubit>()..loadProfile(),
      child: _ProfileView(onBackTap: onBackTap, onLogoutTap: onLogoutTap),
    );
  }
}

class _ProfileView extends StatefulWidget {
  final VoidCallback? onBackTap;
  final VoidCallback? onLogoutTap;

  const _ProfileView({this.onBackTap, this.onLogoutTap});

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final ImagePicker _imagePicker = ImagePicker();
  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  Future<void> _onCameraTap() async {
    final source = await _showImageSourcePicker();
    if (!mounted || source == null) {
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        context.read<ProfileCubit>().uploadProfileImage(pickedFile.path);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick image'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _onVerifyProfileTap() async {
    final source = await _showImageSourcePicker();
    if (!mounted || source == null) {
      return;
    }

    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );

    if (pickedFile == null || !mounted) {
      return;
    }

    context.read<ProfileCubit>().verifyProfile(pickedFile.path);
  }

  Future<ImageSource?> _showImageSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: AppDimensions.spacingMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.textPrimary,
                  ),
                  title: Text(
                    'Camera',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.textPrimary,
                  ),
                  title: Text(
                    'Gallery',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded && state.statusMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.statusMessage!),
              backgroundColor: state.isStatusError
                  ? AppColors.error
                  : AppColors.success,
            ),
          );
          context.read<ProfileCubit>().clearStatusMessage();
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
          return const SizedBox.shrink();
        }

        if (state is ProfileError) {
          return _buildErrorState(state.message);
        }

        if (state is ProfileLoaded) {
          return _buildLoadedState(state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedState(ProfileLoaded state) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<ProfileCubit>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingMd,
        ),
        children: [
          _buildHeader(),
          SizedBox(height: AppDimensions.spacingXl),
          Center(
            child: ProfileAvatar(
              imageUrl: state.profile.profileImageUrl,
              isUploading: state.isUploadingImage,
              onCameraTap: _onCameraTap,
            ),
          ),
          SizedBox(height: AppDimensions.spacingMd),
          Text(
            state.profile.fullName,
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.spacingSm),
          _buildVerificationSection(state),
          SizedBox(height: AppDimensions.spacingXl),
          _buildMyListingsSection(),
          SizedBox(height: AppDimensions.spacingMd),
          _buildMyRatingsSection(state.profile.id),
          SizedBox(height: AppDimensions.spacingXl),
          const ProfileSectionHeader(title: 'ACCOUNT INFORMATION'),
          SizedBox(height: AppDimensions.spacingMd),
          _buildFieldLabel('Full Name'),
          SizedBox(height: AppDimensions.spacingSm),
          ProfileInfoTile(
            icon: Icons.person_outline_rounded,
            value: state.profile.fullName,
          ),
          SizedBox(height: AppDimensions.spacingMd),
          _buildFieldLabel('Email Address'),
          SizedBox(height: AppDimensions.spacingSm),
          ProfileInfoTile(
            icon: Icons.email_outlined,
            value: state.profile.email,
          ),
          SizedBox(height: AppDimensions.spacingXl),
          const ProfileSectionHeader(title: 'SECURITY & PRIVACY'),
          SizedBox(height: AppDimensions.spacingMd),
          _buildSecurityTile(),
          SizedBox(height: AppDimensions.spacingXl),
          _buildLogoutButton(),
          SizedBox(height: AppDimensions.spacingMd),
          _buildVersionText(),
          SizedBox(height: AppDimensions.spacingMd),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (widget.onBackTap != null)
          _buildHeaderIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: widget.onBackTap!,
          )
        else
          SizedBox(width: AppDimensions.dialogIconContainerSize),
        Expanded(
          child: Text(
            'Profile Settings',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(width: AppDimensions.dialogIconContainerSize),
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.dialogIconContainerSize,
        height: AppDimensions.dialogIconContainerSize,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: AppDimensions.spacingSm,
              offset: Offset(0, AppDimensions.spacingXs / 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary,
          size: AppDimensions.iconSizeMd,
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSecurityTile() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Change password flow will be added next'),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.dividerColor),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: AppDimensions.spacingSm,
              offset: Offset(0, AppDimensions.spacingXs / 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: AppDimensions.dialogIconContainerSize - 10,
              height: AppDimensions.dialogIconContainerSize - 10,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_outlined,
                color: AppColors.primary,
                size: AppDimensions.iconSizeMd,
              ),
            ),
            SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Text(
                'Reset Password',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: AppDimensions.iconSizeLg,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyListingsSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyListingsScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.myListingsSectionBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Row(
          children: [
            Container(
              width: AppDimensions.dialogIconContainerSize - 14,
              height: AppDimensions.dialogIconContainerSize - 14,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(
                Icons.list_alt_rounded,
                color: AppColors.white,
                size: AppDimensions.iconSizeMd,
              ),
            ),
            SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Listings',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    'Manage your active listings',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textPrimary,
              size: AppDimensions.iconSizeMd,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRatingsSection(String userId) {
    return GestureDetector(
      onTap: () {
        if (userId.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open ratings now. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MyRatingsScreen(userId: userId)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.myRatingsSectionBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Row(
          children: [
            Container(
              width: AppDimensions.dialogIconContainerSize - 14,
              height: AppDimensions.dialogIconContainerSize - 14,
              decoration: BoxDecoration(
                color: AppColors.info,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(
                Icons.star_rate_rounded,
                color: AppColors.white,
                size: AppDimensions.iconSizeMd,
              ),
            ),
            SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Ratings',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    'See your Ratings & Reviews',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textPrimary,
              size: AppDimensions.iconSizeMd,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSection(ProfileLoaded state) {
    if (state.profile.isVerified) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified,
            color: AppColors.primary,
            size: AppDimensions.iconSizeMd,
          ),
          SizedBox(width: AppDimensions.spacingXs),
          Text(
            'Verified Profile',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Center(
      child: ElevatedButton.icon(
        onPressed: state.isUploadingVerificationDocument
            ? null
            : _onVerifyProfileTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.textDisabled,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingSm,
          ),
        ),
        icon: Icon(
          Icons.verified_user_outlined,
          size: AppDimensions.iconSizeSm,
          color: AppColors.white,
        ),
        label: Text(
          state.isUploadingVerificationDocument
              ? 'Uploading...'
              : 'Verify Profile',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: widget.onLogoutTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: AppDimensions.spacingSm,
              offset: Offset(0, AppDimensions.spacingXs / 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: AppDimensions.iconSizeMd,
            ),
            SizedBox(width: AppDimensions.spacingSm),
            Text(
              'LOGOUT',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionText() {
    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture,
      builder: (context, snapshot) {
        String versionText = 'Version ${AppConfig.appVersion}';

        final packageInfo = snapshot.data;
        if (packageInfo != null) {
          final buildNumber = packageInfo.buildNumber.trim();
          versionText = buildNumber.isEmpty
              ? 'Version ${packageInfo.version}'
              : 'Version ${packageInfo.version}+$buildNumber';
        }

        return Text(
          versionText,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimensions.iconSizeXl,
              color: AppColors.error,
            ),
            SizedBox(height: AppDimensions.spacingSm),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacingMd),
            ElevatedButton(
              onPressed: () => context.read<ProfileCubit>().loadProfile(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
              child: Text(
                'Retry',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
