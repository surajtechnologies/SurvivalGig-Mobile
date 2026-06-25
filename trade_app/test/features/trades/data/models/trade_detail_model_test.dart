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

  test('uses buyer name separately from listing owner name', () {
    final trade = TradeDetailModel.fromResponse({
      'success': true,
      'trade': {
        'id': 'trade-id',
        'status': 'PENDING',
        'buyerId': 'buyer-id',
        'sellerId': 'seller-id',
        'buyer': {'id': 'buyer-id', 'name': 'Buyer Person'},
        'seller': {'id': 'seller-id', 'name': 'Seller Person'},
        'listing': {
          'id': 'listing-id',
          'title': 'Vintage Camera',
          'description': 'Listing description',
          'user': {'id': 'seller-id', 'name': 'Listed Person'},
        },
      },
    }).toEntity();

    expect(trade.buyerName, 'Buyer Person');
    expect(trade.sellerName, 'Seller Person');
    expect(trade.offeredByName, 'Listed Person');
    expect(trade.displayNameFor('buyer-id'), 'Seller Person');
    expect(trade.displayNameFor('seller-id'), 'Buyer Person');
  });

  test(
    'falls back to listing owner id and responder id for participant names',
    () {
      final trade = TradeDetailModel.fromResponse({
        'success': true,
        'trade': {
          'id': 'trade-id',
          'status': 'PENDING',
          'listingOwnerId': 'seller-id',
          'responderId': 'buyer-id',
          'buyer': {'id': 'buyer-id', 'name': 'Buyer Person'},
          'listing': {
            'id': 'listing-id',
            'title': 'Vintage Camera',
            'description': 'Listing description',
            'user': {'id': 'seller-id', 'name': 'Listed Person'},
          },
        },
      }).toEntity();

      expect(trade.buyerId, 'buyer-id');
      expect(trade.sellerId, 'seller-id');
      expect(trade.displayNameFor('buyer-id'), 'Listed Person');
      expect(trade.displayNameFor('seller-id'), 'Buyer Person');
    },
  );

  test('keeps listing points separate from newly offered points', () {
    final trade = TradeDetailModel.fromResponse({
      'success': true,
      'trade': {
        'id': 'trade-id',
        'status': 'PENDING',
        'listingOwnerId': 'seller-id',
        'responderId': 'buyer-id',
        'currentOffererId': 'buyer-id',
        'buyerOfferPoints': 125,
        'listing': {
          'id': 'listing-id',
          'title': 'Vintage Camera',
          'description': 'Listing description',
          'pricePoints': 200,
        },
      },
    }).toEntity();

    expect(trade.points, 200);
    expect(trade.offerPoints, 125);
    expect(trade.isCurrentOfferer('buyer-id'), isTrue);
    expect(trade.isCurrentOfferer('seller-id'), isFalse);
  });
}
