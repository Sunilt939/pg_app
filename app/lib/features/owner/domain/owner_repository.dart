import 'city.dart';
import 'pg_switcher_item.dart';

abstract class OwnerRepository {
  Future<List<City>> getCities();
  Future<List<PgSwitcherItem>> getOwnerPgs();
  Future<String> createPg({
    required String name,
    required String line1,
    required int cityId,
    String? pincode,
    String? area,
    String? contactPhone,
    String genderPolicy = 'any',
  });
}

