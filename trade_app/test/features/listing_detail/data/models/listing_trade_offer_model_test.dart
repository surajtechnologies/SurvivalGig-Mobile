import 'package:flutter_test/flutter_test.dart';
import 'package:trade_app/features/listing_detail/data/models/listing_trade_offer_model.dart';

void main() {
  test('parses pending trade status and offer summary fields', () {
    final trade = ListingTradeOfferModel.fromJson({
      'id': 'trade-1',
      'status': 'pending',
      'buyerOfferPoints': '125',
      'buyerOfferItems': [
        {'description': 'Camping stove'},
      ],
      'buyerOfferServices': [
        {'description': 'Two hours of yard work'},
      ],
    });

    expect(trade.status, 'PENDING');
    expect(trade.buyerOfferPoints, 125);

    final offer = trade.toEntity();
    expect(offer.id, 'trade-1');
    expect(offer.buyerOfferItemDescription, 'Camping stove');
    expect(offer.buyerOfferServiceDescription, 'Two hours of yard work');
  });
}
