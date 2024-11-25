import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();

  Future<LocationData> getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Verificar se o serviço de localização está habilitado
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        throw Exception('Serviço de localização está desativado');
      }
    }

    // Verificar e solicitar permissão
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception('Permissão de localização negada');
      }
    }

    if (permissionGranted == PermissionStatus.deniedForever) {
      throw Exception(
          'Permissão de localização permanentemente negada, não podemos solicitar.');
    }

    // Obter localização atual
    return await _location.getLocation();
  }
}
