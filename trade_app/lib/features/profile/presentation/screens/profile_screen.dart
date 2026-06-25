import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/screens/login_landing_screen.dart';
import '../../../listing_detail/presentation/screens/my_listings_screen.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import 'my_ratings_screen.dart';

/// Profile tab screen
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

bool _profileIsDark(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

Color _profileBackground(BuildContext context) {
  return _profileIsDark(context)
      ? AppColors.dashboardBackground
      : AppColors.background;
}

Color _profileSurface(BuildContext context) {
  return _profileIsDark(context) ? AppColors.dashboardSurface : AppColors.white;
}

Color _profileBorder(BuildContext context) {
  return _profileIsDark(context)
      ? AppColors.dashboardBorder
      : AppColors.dividerColor;
}

Color _profilePrimaryText(BuildContext context) {
  return _profileIsDark(context)
      ? AppColors.textOnDarkPrimary
      : AppColors.textPrimary;
}

Color _profileSecondaryText(BuildContext context) {
  return _profileIsDark(context)
      ? AppColors.textOnDarkSecondary
      : AppColors.textSecondary;
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

  Future<void> _onAvatarTap() async {
    final source = await _showImageSourcePicker();
    if (!mounted || source == null) return;

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
      if (!mounted) return;
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
    if (!mounted || source == null) return;

    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (pickedFile == null || !mounted) return;

    context.read<ProfileCubit>().verifyProfile(pickedFile.path);
  }

  Future<ImageSource?> _showImageSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _profileSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spacingMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SourceTile(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                _SourceTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
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
        if (state is AccountDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginLandingScreen()),
          );
          return;
        }

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
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
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
    final initial = state.profile.fullName.trim().isEmpty
        ? '?'
        : state.profile.fullName.trim()[0].toUpperCase();

    return ColoredBox(
      color: _profileBackground(context),
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<ProfileCubit>().refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppDimensions.spacingMd,
            AppDimensions.spacingMd,
            AppDimensions.spacingMd,
            AppDimensions.spacingXl,
          ),
          children: [
            _buildHeader(),
            SizedBox(height: AppDimensions.spacingLg),
            Center(
              child: _ProfileAvatarButton(
                initial: initial,
                imageUrl: state.profile.profileImageUrl,
                isUploading: state.isUploadingImage,
                onTap: _onAvatarTap,
              ),
            ),
            SizedBox(height: AppDimensions.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    state.profile.fullName,
                    style: AppTextStyles.displayMedium.copyWith(
                      color: _profilePrimaryText(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (state.profile.isVerified) ...[
                  SizedBox(width: AppDimensions.spacingSm),
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.primary,
                    size: AppDimensions.iconSizeMd,
                  ),
                ],
              ],
            ),
            SizedBox(height: AppDimensions.spacingSm),
            Text(
              state.profile.email,
              style: AppTextStyles.bodyMedium.copyWith(
                color: _profileSecondaryText(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacingLg),
            Text(
              'My Active Listings',
              style: AppTextStyles.headlineLarge.copyWith(
                color: _profilePrimaryText(context),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: AppDimensions.spacingMd),
            _ActionTile(
              icon: Icons.list_alt_rounded,
              title: 'My Listings',
              subtitle: 'Manage your active listings',
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyListingsScreen()),
              ),
            ),
            SizedBox(height: AppDimensions.spacingMd),
            _ActionTile(
              icon: Icons.star_rounded,
              title: 'My Ratings',
              subtitle: 'See your ratings and reviews',
              color: AppColors.hybridPin,
              onTap: () {
                if (state.profile.id.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to open ratings now.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyRatingsScreen(userId: state.profile.id),
                  ),
                );
              },
            ),
            SizedBox(height: AppDimensions.spacingMd),
            if (!state.profile.isVerified) ...[
              _ActionTile(
                icon: Icons.verified_user_rounded,
                title: 'Verify Profile',
                subtitle: 'Upload an ID document',
                color: AppColors.primary,
                isLoading: state.isUploadingVerificationDocument,
                onTap: _onVerifyProfileTap,
              ),
              SizedBox(height: AppDimensions.spacingMd),
            ],
            _ActionTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Sign out of this device',
              color: AppColors.spent,
              onTap: _showLogoutConfirmation,
            ),
            SizedBox(height: AppDimensions.spacingMd),
            _ActionTile(
              icon: Icons.delete_forever_rounded,
              title: state.isDeletingAccount ? 'Deleting...' : 'Delete Account',
              subtitle: 'Permanently remove your account',
              color: AppColors.spent,
              isLoading: state.isDeletingAccount,
              onTap: state.isDeletingAccount
                  ? null
                  : () => _showDeleteAccountConfirmation(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (widget.onBackTap != null)
          IconButton(
            onPressed: widget.onBackTap,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
            ),
          )
        else
          SizedBox(width: AppDimensions.iconSizeXl),
        Expanded(
          child: Text(
            'Profile',
            style: AppTextStyles.displayLarge.copyWith(
              color: _profilePrimaryText(context),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _profileSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          title: Text(
            'Logout',
            style: AppTextStyles.headlineMedium.copyWith(
              color: _profilePrimaryText(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Do you want to confirm logout?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: _profileSecondaryText(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _profileSecondaryText(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (widget.onLogoutTap != null) {
                  widget.onLogoutTap!.call();
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginLandingScreen(),
                    ),
                  );
                }
              },
              child: Text(
                'Logout',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.spent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _profileSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          title: Text(
            'Delete Account',
            style: AppTextStyles.headlineMedium.copyWith(
              color: _profilePrimaryText(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Do you want to confirm delete account? This permanently deletes the account in 14 days.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: _profileSecondaryText(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _profileSecondaryText(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<ProfileCubit>().deleteAccount();
              },
              child: Text(
                'Delete',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.spent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
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
              Icons.error_outline_rounded,
              size: AppDimensions.iconSizeXl,
              color: AppColors.error,
            ),
            SizedBox(height: AppDimensions.spacingSm),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: _profileSecondaryText(context),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacingMd),
            ElevatedButton(
              onPressed: () => context.read<ProfileCubit>().loadProfile(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.black,
                elevation: 0,
              ),
              child: Text(
                'Retry',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  final String initial;
  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onTap;

  const _ProfileAvatarButton({
    required this.initial,
    required this.imageUrl,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: isUploading ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 28,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: ClipOval(
              child: isUploading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.black),
                    )
                  : _buildAvatarContent(),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _profileSurface(context),
                shape: BoxShape.circle,
                border: Border.all(color: _profileBorder(context)),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
                size: AppDimensions.iconSizeSm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => _buildInitial(),
      );
    }
    return _buildInitial();
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        initial,
        style: AppTextStyles.displayLarge.copyWith(
          color: AppColors.black,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm + 2,
        ),
        decoration: BoxDecoration(
          color: _profileSurface(context),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: _profileBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: isLoading
                  ? Padding(
                      padding: EdgeInsets.all(AppDimensions.spacingSm),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: AppDimensions.iconSizeMd),
            ),
            SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _profilePrimaryText(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _profileSecondaryText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _profileSecondaryText(context),
              size: AppDimensions.iconSizeMd,
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: _profilePrimaryText(context),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      onTap: onTap,
    );
  }
}
