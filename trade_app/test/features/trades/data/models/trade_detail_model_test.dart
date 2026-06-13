import 'package:flutter_test/flutter_test.dart';
import 'package:trade_app/features/trades/data/models/trade_detail_model.dart';

void main() {
  test('tracks confirmation separately for each trade participant', () {
    final trade = TradeDetailModel.fromResponse({
      'success': true,
      'trade': {
        'id': 'trade-id',
        'status': 'ACCEPTED',
        'listingOwnerId': 'seller-id',
        'responderId': 'buyer-id',
        'buyerId': 'buyer-id',
        'sellerId': 'seller-id',
        'ownerConfirmed': true,
        'responderConfirmed': false,
        'listing': {
          'id': 'listing-id',
          'title': 'PS5 For Sale',
          'description': 'Listing description',
        },
      },
    }).toEntity();

    expect(trade.isParticipant('buyer-id'), isTrue);
    expect(trade.hasConfirmed('buyer-id'), isFalse);
    expect(trade.hasConfirmed('seller-id'), isTrue);
  });
}
