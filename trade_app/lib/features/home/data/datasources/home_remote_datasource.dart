import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/categories_response_model.dart';
import '../models/listings_response_model.dart';
import '../models/map_listing_model.dart';
import '../models/pincode_lookup_response_model.dart';

/// Home remote datasource
/// Responsible for making API calls only
/// NO business logic, NO domain entities
abstract class HomeRemoteDataSource {
  /// Fetch all categories from API
  Future<CategoriesResponseModel> getCategories();

  /// Fetch paginated listings from API
  Future<ListingsResponseModel> getListings({
    required int page,
    int limit = 20,
    double? latitude,
    double? longitude,
    double? radiusKm,
  });

  /// Fetch lightweight map pins within a bounding box
  Future<List<MapListingModel>> getMapListings({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  });

  /// Fetch lightweight map pins around a GPS coordinate
  Future<List<MapListingModel>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 20,
    String? urgencyLevel,
  });

  /// Fetch lightweight map pins inside a polygon boundary
  Future<List<MapListingModel>> getListingsInPolygon({
    required List<({double latitude, double longitude})> polygon,
    int limit = 100,
  });

  /// Fetch city details from US pincode.
  Future<PincodeLookupResponseModel> getLocationByPincode({
    required String pincode,
  });
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final DioClient dioClient;

  HomeRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<CategoriesResponseModel> getCategories() async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.categories,
        options: Options(extra: const {'skipLoading': true}),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          // Handle success response
          if (data['success'] == true || data['status'] == 'success') {
            return CategoriesResponseModel.fromJson(data);
          }

          // Handle failure response
          if (data['success'] == false || data['status'] == 'failure') {
            throw ServerException(
              message:
                  _extractErrorMessage(data) ?? 'Failed to fetch categories',
              code: 'CATEGORIES_FAILED',
              statusCode: response.statusCode,
            );
          }
        }

        throw ServerException(
          message: 'Invalid response format',
          code: 'INVALID_RESPONSE',
          statusCode: response.statusCode,
        );
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to fetch categories',
          code: response.data['code'] ?? 'CATEGORIES_FAILED',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ListingsResponseModel> getListings({
    required int page,
    int limit = 20,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (latitude != null && longitude != null) {
        queryParams['lat'] = latitude;
        queryParams['lng'] = longitude;
        if (radiusKm != null) {
          queryParams['radiusKm'] = radiusKm;
        }
      }

      final response = await dioClient.dio.get(
        ApiEndpoints.listings,
        queryParameters: queryParams,
        options: Options(extra: const {'skipLoading': true}),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          // Handle success response
          if (data['success'] == true || data['listings'] != null) {
            return ListingsResponseModel.fromJson(data);
          }

          // Handle failure response
          if (data['success'] == false) {
            throw ServerException(
              message: _extractErrorMessage(data) ?? 'Failed to fetch listings',
              code: 'LISTINGS_FAILED',
              statusCode: response.statusCode,
            );
          }
        }

        throw ServerException(
          message: 'Invalid response format',
          code: 'INVALID_RESPONSE',
          statusCode: response.statusCode,
        );
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to fetch listings',
          code: response.data['code'] ?? 'LISTINGS_FAILED',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<MapListingModel>> getMapListings({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.listingsMap,
        queryParameters: {
          'swLat': swLat,
          'swLng': swLng,
          'neLat': neLat,
          'neLng': neLng,
        },
        options: Options(extra: const {'skipLoading': true}),
      );

      if (response.statusCode == 200) {
        return _parseMapListingsPayload(response.data);
      }

      throw ServerException(
        message: 'Failed to fetch map listings',
        code: 'MAP_LISTINGS_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<MapListingModel>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 20,
    String? urgencyLevel,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.listingsNearby,
        queryParameters: {
          'lat': latitude,
          'lng': longitude,
          'radiusKm': radiusKm,
          'limit': limit,
          if (urgencyLevel != null && urgencyLevel.isNotEmpty)
            'urgencyLevel': urgencyLevel,
        },
        options: Options(extra: const {'skipLoading': true}),
      );

      if (response.statusCode == 200) {
        return _parseMapListingsPayload(response.data);
      }

      throw ServerException(
        message: 'Failed to fetch nearby listings',
        code: 'NEARBY_LISTINGS_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<MapListingModel>> getListingsInPolygon({
    required List<({double latitude, double longitude})> polygon,
    int limit = 100,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.listingsPolygon,
        data: {
          'polygon': polygon
              .map((point) => [point.longitude, point.latitude])
              .toList(),
          'limit': limit,
        },
        options: Options(extra: const {'skipLoading': true}),
      );

      if (response.statusCode == 200) {
        return _parseMapListingsPayload(response.data);
      }

      throw ServerException(
        message: 'Failed to fetch polygon listings',
        code: 'POLYGON_LISTINGS_FAILED',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<PincodeLookupResponseModel> getLocationByPincode({
    required String pincode,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.usPincodeLookup(pincode),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = PincodeLookupResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );

        if (model.places.isEmpty || model.places.first.placeName.isEmpty) {
          throw const ServerException(
            message: 'City not found for this pincode',
            code: 'PINCODE_CITY_NOT_FOUND',
            statusCode: 404,
          );
        }

        return model;
      }

      throw ServerException(
        message: 'Invalid pincode lookup response',
        code: 'PINCODE_LOOKUP_INVALID_RESPONSE',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Extract error message from API response
  String? _extractErrorMessage(Map<String, dynamic> data) {
    if (data['message'] != null) {
      return data['message'] as String;
    }

    if (data['error'] != null) {
      if (data['error'] is String) {
        return data['error'] as String;
      }
      if (data['error'] is List && (data['error'] as List).isNotEmpty) {
        final firstError = (data['error'] as List).first;
        if (firstError is Map && firstError['message'] != null) {
          return firstError['message'] as String;
        }
      }
    }

    return null;
  }

  List<MapListingModel> _parseMapListingsPayload(dynamic data) {
    final rawList = _extractListPayload(data);
    if (rawList == null) {
      throw const ServerException(
        message: 'Invalid map listings response',
        code: 'INVALID_MAP_LISTINGS_RESPONSE',
      );
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(MapListingModel.fromJsonOrNull)
        .whereType<MapListingModel>()
        .toList();
  }

  List<dynamic>? _extractListPayload(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      for (final key in const [
        'listings',
        'pins',
        'results',
        'items',
        'ads',
        'adListings',
        'mapListings',
        'markers',
        'nearbyListings',
        'docs',
        'rows',
        'records',
      ]) {
        final value = data[key];
        if (value is List) {
          return value;
        }
      }

      final wrappedData = data['data'];
      if (wrappedData is List) {
        return wrappedData;
      }
      if (wrappedData is Map<String, dynamic>) {
        return _extractListPayload(wrappedData);
      }

      for (final value in data.values) {
        if (value is List) {
          return value;
        }
        if (value is Map<String, dynamic>) {
          final nestedList = _extractListPayload(value);
          if (nestedList != null) {
            return nestedList;
          }
        }
      }
    }

    return null;
  }

  /// Handle Dio errors and convert to ServerException
  ServerException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ServerException(
        message: 'Connection timeout. Please try again.',
        code: 'TIMEOUT',
        statusCode: null,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return ServerException(
        message: 'No internet connection',
        code: 'NO_INTERNET',
        statusCode: null,
      );
    }

    if (e.response != null) {
      if (e.response?.statusCode == 404 &&
          e.requestOptions.uri.toString().contains('api.zippopotam.us')) {
        return const ServerException(
          message: 'Invalid pincode. Please enter a valid US pincode.',
          code: 'PINCODE_NOT_FOUND',
          statusCode: 404,
        );
      }

      final data = e.response!.data;
      String? message;

      if (data is Map<String, dynamic>) {
        message = _extractErrorMessage(data);
      }

      return ServerException(
        message: message ?? 'Server error occurred',
        code: 'SERVER_ERROR',
        statusCode: e.response?.statusCode,
      );
    }

    return ServerException(
      message: e.message ?? 'An unexpected error occurred',
      code: 'UNKNOWN_ERROR',
      statusCode: null,
    );
  }
}
