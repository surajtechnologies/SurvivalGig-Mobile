import 'package:flutter_test/flutter_test.dart';
import 'package:trade_app/features/trades/data/models/trade_summary_model.dart';

void main() {
  test('shows the other trade participant in the chat list', () {
    final trade = TradeSummaryModel.fromJson({
      'id': 'trade-id',
      'listingOwnerId': 'seller-id',
      'responderId': 'buyer-id',
      'buyerId': 'buyer-id',
      'sellerId': 'seller-id',
      'listing': {
        'id': 'listing-id',
        'userId': 'seller-id',
        'title': 'PS5 For Sale',
        'description': 'Listing description',
      },
      'buyer': {'id': 'buyer-id', 'name': 'Dhanusha Man'},
      'seller': {'id': 'seller-id', 'name': 'Dhanush'},
    }).toEntity();

    expect(trade.displayNameFor('seller-id'), 'Dhanusha Man');
    expect(trade.displayNameFor('buyer-id'), 'Dhanush');
  });
}
