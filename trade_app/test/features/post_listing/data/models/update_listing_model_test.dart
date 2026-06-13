import 'package:flutter_test/flutter_test.dart';
import 'package:trade_app/features/home/data/models/listing_model.dart';
import 'package:trade_app/features/post_listing/data/models/update_listing_model.dart';

void main() {
  group('UpdateListingRequestModel', () {
    test('serializes every field in the update-listing API contract', () {
      final request = UpdateListingRequestModel(
        listingId: 'listing-1',
        title: 'Updated title',
        pricePoints: 450,
        description: 'Updated description',
        latitude: 37.7749,
        longitude: -122.4194,
        urgencyLevel: 'HIGH',
        expiresAt: DateTime(2026, 8, 1, 18, 30),
        deletePhotoIds: const ['photo-1', ' photo-2 ', 'photo-1', ''],
      );

      expect(request.toJson(), {
        'title': 'Updated title',
        'pricePoints': 450,
        'description': 'Updated description',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'urgencyLevel': 'HIGH',
        'expiresAt': '2026-08-01T00:00:00.000Z',
        'deletePhotoIds': ['photo-1', 'photo-2'],
      });
    });

    test('sends null clearing values and an empty photo deletion list', () {
      final request = UpdateListingRequestModel(
        listingId: 'listing-1',
        title: 'Updated title',
        pricePoints: null,
        description: 'Updated description',
        latitude: null,
        longitude: null,
        urgencyLevel: null,
        expiresAt: null,
        deletePhotoIds: const [],
      );

      expect(request.toJson(), {
        'title': 'Updated title',
        'description': 'Updated description',
        'urgencyLevel': null,
        'expiresAt': null,
        'deletePhotoIds': <String>[],
      });
    });
  });

  test('listing details retain photo IDs for update deletion requests', () {
    final listing = ListingModel.fromJson({
      'id': 'listing-1',
      'title': 'Listing',
      'photos': [
        {
          'id': 'photo-1',
          'listingId': 'listing-1',
          'url': 'https://example.com/photo.jpg',
          'sortOrder': 0,
        },
      ],
      'user': {'id': 'user-1', 'name': 'User'},
    }).toEntity();

    expect(listing.photos.single.id, 'photo-1');
  });

  test('listing details retain locationLat and locationLng coordinates', () {
    final listing = ListingModel.fromJson({
      'id': 'listing-1',
      'title': 'Listing',
      'locationLat': '13.0827',
      'locationLng': '80.2707',
      'user': {'id': 'user-1', 'name': 'User'},
    }).toEntity();

    expect(listing.latitude, 13.0827);
    expect(listing.longitude, 80.2707);
  });

  test('listing details retain nested GeoJSON coordinates', () {
    final listing = ListingModel.fromJson({
      'id': 'listing-1',
      'title': 'Listing',
      'geo_location': {
        'type': 'Point',
        'coordinates': [80.2707, 13.0827],
      },
      'user': {'id': 'user-1', 'name': 'User'},
    }).toEntity();

    expect(listing.latitude, 13.0827);
    expect(listing.longitude, 80.2707);
  });
}
