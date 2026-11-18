abstract final class RoutePaths {
  static const startup = '/';

  // Auth & Gate
  static const signIn = '/sign-in';
  static const verify = '/verify';
  static const gate = '/gate';
  static const gateGuest = '/gate/guest';

  // Owner Shell & Tabs
  static const ownerHome = '/owner/home';
  static const ownerGuests = '/owner/guests';
  static const ownerPayments = '/owner/payments';
  static const ownerMore = '/owner/more';

  // Owner Subroutes
  static const ownerPgNew = '/owner/pg/new';
  static const ownerGuestsNew = '/owner/guests/new';
  static const ownerGuestDetail = '/owner/guests/:stayId';
  static const ownerGuestPay = '/owner/guests/:stayId/pay';
  static const ownerPaymentDetail = '/owner/payments/:paymentId';
  static const ownerCollections = '/owner/collections';
  static const ownerRooms = '/owner/rooms';
  static const ownerRoomsNew = '/owner/rooms/new';
  static const ownerRoomDetail = '/owner/rooms/:roomId';
  static const ownerAccounts = '/owner/accounts';
  static const ownerAccountsNew = '/owner/accounts/new';
  static const ownerAccountDetail = '/owner/accounts/:id';
  static const ownerReminders = '/owner/reminders';
  static const ownerSettings = '/owner/settings';

  // Guest Shell & Tabs
  static const guestHome = '/guest/home';
  static const guestHistory = '/guest/history';
  static const guestProfile = '/guest/profile';

  // Guest Subroutes
  static const guestPay = '/guest/pay/:stayId';
  static const guestStay = '/guest/stay/:stayId';

  // Shared
  static const profile = '/profile';
  static const receipt = '/receipt/:paymentId';
  static const notifications = '/notifications';

  // Dev
  static const devGallery = '/dev/gallery';
}

