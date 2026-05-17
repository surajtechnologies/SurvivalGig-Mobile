import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

const _kDark = Color(0xFF0D0D0D);

/// Full-screen address / city / postcode search.
/// Returns the selected address string to the caller via Navigator.pop(result).
class HomeSearchScreen extends StatefulWidget {
  const HomeSearchScreen({super.key});

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  List<Placemark> _suggestions = [];
  List<Location> _locations = [];
  bool _loading = false;
  String _error = '';

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final query = _ctrl.text.trim();
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _locations = [];
        _error = '';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _fetchSuggestions(query),
    );
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final locs = await locationFromAddress(query);
      if (!mounted) return;
      if (locs.isEmpty) {
        setState(() {
          _suggestions = [];
          _locations = [];
          _loading = false;
          _error = 'No results found';
        });
        return;
      }
      // Reverse-geocode the first few hits to get readable place names
      final marks = <Placemark>[];
      final validLocs = <Location>[];
      for (final loc in locs.take(5)) {
        try {
          final pm = await placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          if (pm.isNotEmpty) {
            marks.add(pm.first);
            validLocs.add(loc);
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _suggestions = marks;
        _locations = validLocs;
        _loading = false;
        _error = marks.isEmpty ? 'No results found' : '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _locations = [];
        _loading = false;
        _error = 'Could not search — check connection';
      });
    }
  }

  void _submitQuery() {
    final q = _ctrl.text.trim();
    if (q.isNotEmpty) Navigator.pop(context, q);
  }

  void _selectSuggestion(int index) {
    // Return a precise "lat,lng" string so the cubit can geocode it exactly,
    // or just return the human-readable address string.
    final loc = _locations[index];
    final address = _formatAddress(_suggestions[index]);
    // Return coordinates encoded as a string so the cubit geocodes them precisely.
    Navigator.pop(
      context,
      address.isNotEmpty ? address : '${loc.latitude},${loc.longitude}',
    );
  }

  String _formatAddress(Placemark p) {
    final parts = <String>[];
    if (p.name != null && p.name!.isNotEmpty && p.name != p.locality) {
      parts.add(p.name!);
    }
    if (p.locality != null && p.locality!.isNotEmpty) {
      parts.add(p.locality!);
    }
    if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
      parts.add(p.administrativeArea!);
    }
    if (p.country != null && p.country!.isNotEmpty) {
      parts.add(p.country!);
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      appBar: AppBar(
        backgroundColor: _kDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: 'Search address, city or postcode…',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white38),
            border: InputBorder.none,
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 18,
                    ),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() {
                        _suggestions = [];
                        _error = '';
                      });
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submitQuery(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white10),
        ),
      ),
      body: Column(
        children: [
          // Loading bar
          if (_loading)
            const LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: Colors.transparent,
              minHeight: 2,
            ),

          // Results list
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_ctrl.text.trim().length < 3) {
      return _buildHint();
    }
    if (!_loading && _error.isNotEmpty) {
      return Center(
        child: Text(
          _error,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white38),
        ),
      );
    }
    if (_suggestions.isEmpty && !_loading) {
      return _buildHint();
    }
    return ListView.separated(
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) =>
          const Divider(color: Colors.white10, height: 1),
      itemBuilder: (_, i) {
        final p = _suggestions[i];
        final address = _formatAddress(p);
        return ListTile(
          leading: const Icon(
            Icons.location_on_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          title: Text(
            address.isNotEmpty ? address : 'Unknown location',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          subtitle: p.postalCode != null && p.postalCode!.isNotEmpty
              ? Text(
                  p.postalCode!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white38,
                  ),
                )
              : null,
          onTap: () => _selectSuggestion(i),
        );
      },
    );
  }

  Widget _buildHint() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, color: Colors.white12, size: 56),
          const SizedBox(height: 12),
          Text(
            'Type at least 3 characters\nto search for a location',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white24),
          ),
        ],
      ),
    );
  }
}
