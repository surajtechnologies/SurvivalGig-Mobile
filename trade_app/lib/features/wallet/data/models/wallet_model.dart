import '../../domain/entities/wallet_summary.dart';

/// Wallet summary model (DTO)
class WalletModel {
  final int currentPoints;
  final int pointsInEscrow;

  const WalletModel({
    required this.currentPoints,
    required this.pointsInEscrow,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final payload = _extractPayload(json);

    return WalletModel(
      currentPoints: _resolveCurrentPoints(payload),
      pointsInEscrow: _resolvePointsInEscrow(payload),
    );
  }

  static WalletModel fromResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid wallet response');
    }

    return WalletModel.fromJson(data);
  }

  Map<String, dynamic> toJson() {
    return {'currentPoints': currentPoints, 'pointsInEscrow': pointsInEscrow};
  }

  WalletSummary toEntity() {
    return WalletSummary(
      currentPoints: currentPoints,
      pointsInEscrow: pointsInEscrow,
    );
  }

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> json) {
    final data = json['data'];

    if (data is Map<String, dynamic>) {
      final wallet = data['wallet'];
      if (wallet is Map<String, dynamic>) {
        return wallet;
      }

      final user = data['user'];
      if (user is Map<String, dynamic>) {
        final userWallet = user['wallet'];
        if (userWallet is Map<String, dynamic>) {
          return userWallet;
        }

        return user;
      }

      return data;
    }

    final wallet = json['wallet'];
    if (wallet is Map<String, dynamic>) {
      return wallet;
    }

    final user = json['user'];
    if (user is Map<String, dynamic>) {
      final userWallet = user['wallet'];
      if (userWallet is Map<String, dynamic>) {
        return userWallet;
      }

      return user;
    }

    return json;
  }

  static int _resolveCurrentPoints(Map<String, dynamic> payload) {
    const keys = <String>[
      'currentPoints',
      'current_points',
      'currentPointBalance',
      'current_point_balance',
      'balance',
      'walletBalance',
      'wallet_balance',
      'points',
      'availablePoints',
      'available_points',
      'pointsAvailable',
      'points_available',
      'available',
      'totalPoints',
      'total_points',
    ];

    return _readFromPayload(payload, keys);
  }

  static int _resolvePointsInEscrow(Map<String, dynamic> payload) {
    const keys = <String>[
      'pointsInEscrow',
      'points_in_escrow',
      'escrowPoints',
      'escrow_points',
      'escrow',
      'escrowBalance',
      'escrow_balance',
      'pointsEscrow',
      'points_escrow',
      'inEscrow',
      'in_escrow',
      'heldPoints',
      'held_points',
      'pendingPoints',
      'pending_points',
    ];

    return _readFromPayload(payload, keys);
  }

  static int _readFromPayload(Map<String, dynamic> payload, List<String> keys) {
    final directValue = _readIntFromKeys(payload, keys);
    if (directValue != null) {
      return directValue;
    }

    final nestedMaps = <Map<String, dynamic>?>[
      _extractMap(payload['wallet']),
      _extractMap(payload['summary']),
      _extractMap(payload['balance']),
      _extractMap(payload['points']),
      _extractMap(payload['user']),
    ];

    for (final map in nestedMaps) {
      if (map == null) {
        continue;
      }

      final nestedValue = _readIntFromKeys(map, keys);
      if (nestedValue != null) {
        return nestedValue;
      }

      final balanceMap = _extractMap(map['balance']);
      if (balanceMap == null) {
        continue;
      }

      final balanceValue = _readIntFromKeys(balanceMap, keys);
      if (balanceValue != null) {
        return balanceValue;
      }
    }

    return 0;
  }

  static int? _readIntFromKeys(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = _readInt(source[key]);
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  static Map<String, dynamic>? _extractMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    return null;
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty) {
        return null;
      }

      return int.tryParse(normalized) ?? double.tryParse(normalized)?.toInt();
    }

    return null;
  }
}
