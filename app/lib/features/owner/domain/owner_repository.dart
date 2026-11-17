import 'city.dart';

abstract class OwnerRepository {
  Future<List<City>> getCities();
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

