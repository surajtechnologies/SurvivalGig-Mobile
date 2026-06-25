# Backend API Notes for Trade, Escrow, Wallet, and Chat Flows

This document is for the backend team to verify the APIs needed by the app for direct offer acceptance, new offer negotiation, escrow movement, wallet transactions, trade confirmation, and chat.

Base API used by the app:

```text
https://barterx-backend-a7fym27foa-uc.a.run.app/api
```

All protected APIs require:

```text
Authorization: Bearer <accessToken>
```

In the examples below, `$20` and `$10` mean points value `20` and `10`. The app displays points as money-like values in the scenario, but the API field is integer points.

## Scenario 1: APIs / Endpoints Needed

| App action | Method | Endpoint | Request body | Expected backend behavior |
| --- | --- | --- | --- | --- |
| Accept Offer | `POST` | `/trades/buy-now/{listingId}` | `{}` or `{ "message": "I want to buy this now!" }` | Create trade with `ACCEPTED` status and move buyer points into escrow immediately. |
| Make New Offer | `POST` | `/trades` | `{ "listingId": "...", "offerType": "points", "offerPoints": 10, "message": "..." }` | Create trade offer with `PENDING` status. Points should move to escrow only after the offer is accepted. |
| Accept New Offer | `PATCH` | `/trades/{tradeId}/accept` | None | Change trade to `ACCEPTED`, move accepted buyer points into escrow, and create wallet transaction such as `ESCROW_HOLD`. |
| Reject New Offer | `PATCH` | `/trades/{tradeId}/reject` | Optional: `{ "reason": "..." }` | Change trade to `REJECTED`. No escrow should remain for rejected offer. |
| Confirm Trade | `PATCH` | `/trades/{tradeId}/confirm` | None | Mark trade confirmation. When completion rules are satisfied, release escrow to seller and clear buyer escrow. |
| Chat - Send Message | `POST` | `/trades/{tradeId}/messages` | `{ "content": "Hi!" }` | Save trade chat message and notify the other participant. |

## Scenario 2.1: User B Accepts User A's $20 Listing Immediately

Goal: User B directly accepts User A's listed $20 price. User B's points move to escrow immediately. After trade completion, User A receives $20 and User B escrow becomes `0`.

1. User A creates/posts a listing for 20 points.
   - API: `POST /listings`
   - Backend should store `pricePoints: 20`, listing owner as User A, and listing status as active.

2. User B opens/views the listing.
   - API: `GET /listings/{listingId}`
   - Response should include `pricePoints: 20`, listing owner, listing status, and enough detail to show the Accept Offer button.

3. User B taps `Accept Offer`.
   - API: `POST /trades/buy-now/{listingId}`
   - Body can be `{}`.
   - Backend should create a trade with `ACCEPTED` status.
   - Backend should move 20 points from User B available balance into User B escrow immediately.
   - Expected wallet state after this step:
     - User B available/current points decreases by 20.
     - User B `pointsInEscrow` increases by 20.
     - User A is not credited yet.

4. App verifies User B wallet detail.
   - API: `GET /users/me/wallet` using User B token.
   - Expected result:
     - `pointsInEscrow = 20`
     - available/current points is reduced by 20.

5. App verifies User B transaction list.
   - API: `GET /users/me/wallet/transactions?page=1&limit=20`
   - Expected result:
     - A transaction exists for the 20-point escrow hold.
     - Suggested transaction type: `ESCROW_HOLD`.

6. App opens trade chat after acceptance.
   - API: `GET /trades/{tradeId}/messages?page=1&limit=50`
   - API: `POST /trades/{tradeId}/messages`
   - The app may send/open with message: `Hi, I accept your offer`.

7. Trade/service/item exchange happens outside the API.
   - No wallet release should happen before completion confirmation.

8. User A confirms trade completion.
   - API: `PATCH /trades/{tradeId}/confirm`
   - Backend should mark User A confirmation.
   - If backend requires both parties to confirm, keep trade accepted until User B also confirms.
   - If User A confirmation is enough for this flow, complete trade and release escrow.

9. Backend completes the trade and releases escrow.
   - User A wallet is credited with 20 points.
   - User B `pointsInEscrow` decreases by 20.
   - Final User B `pointsInEscrow = 0`.
   - Trade status becomes `COMPLETED`.

10. App verifies final wallet and transactions.
    - User B API: `GET /users/me/wallet`
    - User A API: `GET /users/me/wallet`
    - Transaction API: `GET /users/me/wallet/transactions?page=1&limit=20`
    - Expected transactions:
      - User B: escrow hold and escrow release/payment completed entry.
      - User A: credit/received entry for 20 points.

## Scenario 2.2: User B Makes a New $10 Offer Instead of Directly Accepting

Goal: User A posts listing for $20, but User B makes a $10 offer. After User A accepts the new offer, $10 moves into User B escrow. After completion confirmation, User A receives $10 and User B escrow becomes `0`.

1. User A creates/posts a listing for 20 points.
   - API: `POST /listings`
   - Backend stores User A as listing owner and `pricePoints: 20`.

2. User B opens/views the listing.
   - API: `GET /listings/{listingId}`
   - User B sees original price of 20 points and chooses Make Offer.

3. User B makes a new offer for 10 points.
   - API: `POST /trades`
   - Body:

```json
{
  "listingId": "{listingId}",
  "offerType": "points",
  "offerPoints": 10,
  "message": "I can offer 10 points"
}
```

4. Backend creates a pending trade offer.
   - Trade status should be `PENDING`.
   - Accepted points should be `buyerOfferPoints: 10`.
   - No escrow should be held yet unless the backend intentionally reserves points at offer creation.
   - Recommended expected wallet state at this stage:
     - User B available/current points unchanged.
     - User B `pointsInEscrow = 0`.

5. User A views pending offers for the listing.
   - API: `GET /listings/{listingId}/trades?status=PENDING`
   - Response should include User B's pending 10-point offer.

6. User A accepts User B's new offer.
   - API: `PATCH /trades/{tradeId}/accept`
   - Backend should change trade status to `ACCEPTED`.
   - Backend should move 10 points from User B available/current points to User B escrow.
   - Backend should create wallet transaction such as `ESCROW_HOLD` for 10 points.

7. App verifies User B wallet after User A accepts.
   - API: `GET /users/me/wallet` using User B token.
   - Expected result:
     - User B `pointsInEscrow = 10`
     - User B available/current points decreases by 10.

8. App verifies User B transaction list.
   - API: `GET /users/me/wallet/transactions?page=1&limit=20`
   - Expected result:
     - Transaction list contains 10-point escrow hold.

9. App opens trade chat.
   - API: `GET /trades/{tradeId}/messages?page=1&limit=50`
   - API: `POST /trades/{tradeId}/messages`
   - App may send acceptance/chat message after `PATCH /accept`.

10. Trade/service/item exchange happens outside the API.
    - Trade remains `ACCEPTED`.
    - User B escrow remains 10 until completion.

11. User A confirms trade completion.
    - API: `PATCH /trades/{tradeId}/confirm`
    - Backend should mark User A confirmation.
    - If both-party confirmation is required, wait for User B confirmation before release.
    - If User A confirmation is enough for this flow, release escrow immediately.

12. Backend completes trade and releases the 10 points.
    - User A wallet is credited with 10 points.
    - User B `pointsInEscrow` decreases by 10.
    - Final User B `pointsInEscrow = 0`.
    - Trade status becomes `COMPLETED`.

13. App verifies final wallet and transaction state.
    - User B API: `GET /users/me/wallet`
    - User A API: `GET /users/me/wallet`
    - Transaction API: `GET /users/me/wallet/transactions?page=1&limit=20`
    - Expected result:
      - User A has a 10-point credit/received transaction.
      - User B escrow is cleared to `0`.
      - User B has transaction history for escrow hold and completed payment/release.

## Backend Checks Needed

1. `POST /trades/buy-now/{listingId}` must create an accepted trade and escrow the listed price immediately.
2. `POST /trades` with `offerType: "points"` must create a pending offer with the offered amount.
3. `PATCH /trades/{tradeId}/accept` must escrow the accepted offer amount, not the original listing amount.
4. `PATCH /trades/{tradeId}/reject` must not leave any points in escrow.
5. `PATCH /trades/{tradeId}/confirm` must release escrow to the seller only when the backend's completion rule is satisfied.
6. Wallet summary must return both available/current points and escrow points.
7. Wallet transactions must show escrow hold, escrow release/payment, and seller credit entries.
8. Chat APIs must work for `PENDING`, `ACCEPTED`, and completed trade history. Cancelled/rejected trades should be handled consistently.

## Response Fields the App Can Read

Wallet summary:

```json
{
  "wallet": {
    "currentPoints": 80,
    "pointsInEscrow": 20
  }
}
```

The app can also read alternate names such as `pointsAvailable` and `pointsEscrowed`.

Trade detail:

```json
{
  "trade": {
    "id": "trade-id",
    "status": "ACCEPTED",
    "listingId": "listing-id",
    "buyerId": "user-b-id",
    "sellerId": "user-a-id",
    "buyerOfferPoints": 10,
    "buyerEscrowAmount": 10,
    "buyerConfirmed": false,
    "sellerConfirmed": false
  }
}
```

Chat message:

```json
{
  "message": {
    "id": "message-id",
    "content": "Hi!",
    "senderId": "user-id",
    "senderName": "User Name",
    "createdAt": "2026-06-24T10:00:00.000Z"
  }
}
```
