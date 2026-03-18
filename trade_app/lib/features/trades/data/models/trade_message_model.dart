import '../../domain/entities/trade_message.dart';

/// Trade message model (DTO)
class TradeMessageModel {
  final String id;
  final String content;
  final String? senderId;
  final String? senderName;
  final DateTime? createdAt;

  const TradeMessageModel({
    required this.id,
    required this.content,
    this.senderId,
    this.senderName,
    this.createdAt,
  });

  factory TradeMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = _readMap(json['sender']) ??
        _readMap(json['user']) ??
        _readMap(json['from']) ??
        _readMap(json['author']);

    final senderId = _readString(json['senderId']) ??
        _readString(json['sender_id']) ??
        _readString(json['userId']) ??
        _readString(json['user_id']) ??
        _readString(json['fromUserId']) ??
        _readString(json['authorId']) ??
        _readString(sender?['id']) ??
        _readString(sender?['userId']) ??
        _readString(sender?['user_id']);

    final senderName = _readString(json['senderName']) ??
        _readString(json['sender_name']) ??
        _readString(json['userName']) ??
        _readString(json['username']) ??
        _readString(sender?['name']) ??
        _readString(sender?['fullName']) ??
        _readString(sender?['username']);

    final content = _readString(json['content']) ??
        _readString(json['message']) ??
        _readString(json['text']) ??
        _readString(json['body']) ??
        '';

    final createdAt = _readDateTime(
      json['createdAt'] ??
          json['created_at'] ??
          json['timestamp'] ??
          json['sentAt'] ??
          json['sent_at'],
    );

    return TradeMessageModel(
      id: _readString(json['id']) ??
          _readString(json['messageId']) ??
          _readString(json['message_id']) ??
          '',
      content: content,
      senderId: senderId,
      senderName: senderName,
      createdAt: createdAt,
    );
  }

  TradeMessage toEntity() {
    return TradeMessage(
      id: id,
      content: content,
      senderId: senderId,
      senderName: senderName,
      createdAt: createdAt,
    );
  }

  static List<TradeMessageModel> listFromResponse(dynamic data) {
    final messages = _extractMessagesList(data);
    return messages
        .whereType<Map<String, dynamic>>()
        .map(TradeMessageModel.fromJson)
        .toList();
  }

  static TradeMessageModel fromResponse(dynamic data) {
    final message = _extractMessageJson(data);
    return TradeMessageModel.fromJson(message);
  }

  static Map<String, dynamic> _extractMessageJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      final payload = data['data'] ?? data;
      if (payload is Map<String, dynamic>) {
        final message = payload['message'] ??
            payload['data'] ??
            payload['item'] ??
            payload;
        if (message is Map<String, dynamic>) {
          return message;
        }
      }
    }

    throw const FormatException('Invalid message response');
  }

  static List<dynamic> _extractMessagesList(dynamic data) {
    List<dynamic>? messages;

    if (data is Map<String, dynamic>) {
      final payload = data['data'] ?? data;

      if (payload is Map<String, dynamic>) {
        messages = _readList(payload['messages']) ??
            _readList(payload['items']) ??
            _readList(payload['results']) ??
            _readList(payload['data']);
      } else if (payload is List) {
        messages = payload;
      }

      messages ??= _readList(data['messages']) ?? _readList(data['data']);
    } else if (data is List) {
      messages = data;
    }

    if (messages == null) {
      throw const FormatException('Invalid messages response');
    }

    return messages;
  }

  static List<dynamic>? _readList(dynamic value) {
    if (value is List) return value;
    return null;
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  static String? _readString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    if (value is num) {
      final milliseconds = value > 1000000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds.toInt(), isUtc: true);
    }
    return null;
  }
}
