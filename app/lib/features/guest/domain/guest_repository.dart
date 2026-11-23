import 'guest_home_bundle.dart';

abstract class GuestRepository {
  Future<GuestHomeBundle> getGuestHomeData();
}

