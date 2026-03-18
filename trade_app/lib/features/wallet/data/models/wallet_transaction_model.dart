import '../../../../config/env/app_config.dart';
import '../../domain/entities/wallet_transaction.dart';

/// Wallet transaction model (DTO)
class WalletTransactionModel {
  final String id;
  final String counterpartyName;
  final String title;
  final String? description;
  final String? counterpartyAvatarUrl;
  final int points;
  final bool isReceived;
  final DateTime? createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.counterpartyName,
    required this.title,
    this.description,
    this.counterpartyAvatarUrl,
    required this.points,
    required this.isReceived,
    this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    final payload = _extractPayload(json);
    final listing = _extractMap(payload['listing']);
    final amount =
        _readInt(payload['points']) ??
        _readInt(payload['amount']) ??
        _readInt(payload['delta']) ??
        _readInt(payload['value']) ??
        0;

    final directionValue =
        _readString(payload['direction']) ??
        _readString(payload['type']) ??
        _readString(payload['transactionType']) ??
        _readString(payload['flow']);

    final parsedDirection = _parseDirection(directionValue);
    final isReceived = parsedDirection ?? amount >= 0;

    final counterparty = _extractCounterparty(payload);

    return WalletTransactionModel(
      id:
          _readString(payload['id']) ??
          _readString(payload['transactionId']) ??
          _readString(payload['referenceId']) ??
          '',
      counterpartyName: counterparty.name ?? 'Unknown User',
      title:
          _readString(listing?['title']) ??
          _readString(payload['title']) ??
          _readString(payload['reason']) ??
          _readString(payload['transactionType']) ??
          'Wallet Transaction',
      description:
          _readString(payload['description']) ??
          _readString(payload['message']) ??
          _readString(payload['note']) ??
          _readString(listing?['description']),
      counterpartyAvatarUrl: _normalizeImageUrl(counterparty.avatarUrl),
      points: amount.abs(),
      isReceived: isReceived,
      createdAt:
          _readDateTime(payload['createdAt']) ??
          _readDateTime(payload['created_at']) ??
          _readDateTime(payload['transactionDate']) ??
          _readDateTime(payload['transaction_date']) ??
          _readDateTime(payload['timestamp']) ??
          _readDateTime(payload['date']) ??
          _readDateTime(payload['updatedAt']) ??
          _readDateTime(payload['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'counterpartyName': counterpartyName,
      'title': title,
      if (description != null) 'description': description,
      if (counterpartyAvatarUrl != null)
        'counterpartyAvatarUrl': counterpartyAvatarUrl,
      'points': points,
      'isReceived': isReceived,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  WalletTransaction toEntity() {
    return WalletTransaction(
      id: id,
      counterpartyName: counterpartyName,
      title: title,
      description: description,
      counterpartyAvatarUrl: counterpartyAvatarUrl,
      points: points,
      isReceived: isReceived,
      createdAt: createdAt,
    );
  }

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      final transaction = data['transaction'];
      if (transaction is Map<String, dynamic>) {
        return transaction;
      }
      return data;
    }

    final transaction = json['transaction'];
    if (transaction is Map<String, dynamic>) {
      return transaction;
    }

    return json;
  }

  static _Counterparty _extractCounterparty(Map<String, dynamic> payload) {
    final candidates = <dynamic>[
      payload['counterparty'],
      payload['otherUser'],
      payload['user'],
      payload['fromUser'],
      payload['toUser'],
    ];

    for (final candidate in candidates) {
      if (candidate is! Map<String, dynamic>) {
        continue;
      }

      final name =
          _readString(candidate['name']) ??
          _readString(candidate['fullName']) ??
          _readString(candidate['username']);
      final avatar =
          _readString(candidate['avatarUrl']) ??
          _readString(candidate['avatar']) ??
          _readString(candidate['imageUrl']) ??
          _readString(candidate['image']) ??
          _readString(candidate['profileImage']);

      if (name != null || avatar != null) {
        return _Counterparty(name: name, avatarUrl: avatar);
      }
    }

    return const _Counterparty();
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

  static String? _readString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    if (value is int) {
      // Accept both second and millisecond unix timestamps.
      final isMilliseconds = value.abs() >= 1000000000000;
      return DateTime.fromMillisecondsSinceEpoch(
        isMilliseconds ? value : value * 1000,
      );
    }

    if (value is num) {
      final rawValue = value.toInt();
      final isMilliseconds = rawValue.abs() >= 1000000000000;
      return DateTime.fromMillisecondsSinceEpoch(
        isMilliseconds ? rawValue : rawValue * 1000,
      );
    }

    return null;
  }

  static bool? _parseDirection(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    const incoming = <String>{
      'credit',
      'credited',
      'receive',
      'received',
      'incoming',
      'in',
      'earn',
      'earned',
      'add',
      'added',
      'deposit',
      'deposited',
    };

    const outgoing = <String>{
      'debit',
      'debited',
      'spend',
      'spent',
      'outgoing',
      'out',
      'deduct',
      'deducted',
      'withdraw',
      'withdrawn',
      'redeem',
      'redeemed',
      'payment',
    };

    if (incoming.contains(normalized)) {
      return true;
    }

    if (outgoing.contains(normalized)) {
      return false;
    }

    return null;
  }

  static String? _normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final baseUrl = AppConfig.baseUrl;
    if (url.startsWith('/api/')) {
      final trimmedBase = baseUrl.endsWith('/api')
          ? baseUrl.substring(0, baseUrl.length - 4)
          : baseUrl;
      return '$trimmedBase$url';
    }

    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }

    return '$baseUrl/$url';
  }
}

class _Counterparty {
  final String? name;
  final String? avatarUrl;

  const _Counterparty({this.name, this.avatarUrl});
}
