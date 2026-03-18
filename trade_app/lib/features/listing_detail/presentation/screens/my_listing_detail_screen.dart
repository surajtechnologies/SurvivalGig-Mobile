import 'package:flutter/material.dart';
import 'listing_detail_screen.dart';

/// Detail screen for a listing owned by the current user.
class MyListingDetailScreen extends StatelessWidget {
  final String listingId;

  const MyListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context) {
    return ListingDetailScreen(listingId: listingId, isOwnerView: true);
  }
}
