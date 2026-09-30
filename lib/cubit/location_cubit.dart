import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit() : super(LocationState());

  static const int locationTimeoutSeconds = 10;

  Future<void> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(state.copyWith(errorMessage: 'GPS/Lokasi perangkat belum aktif.'));
        return;
      }

      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        emit(state.copyWith(errorMessage: 'Location permission denied'));
        return;
      }

      // Get accurate location without distanceFilter to ensure it returns immediately
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      final currentLocation = LatLng(position.latitude, position.longitude);
      _calculateRadius(currentLocation);

      emit(
        state.copyWith(
          currentLocation: currentLocation,
          gpsAccuracy: position.accuracy,
          isMocked: position.isMocked,
          errorMessage: null, // clear previous error
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Gagal mendapatkan lokasi: $e'));
    }
  }

  Future<bool> _checkLocationPermission() async {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result == LocationPermission.whileInUse ||
          result == LocationPermission.always;
    }
    return status == LocationPermission.whileInUse ||
        status == LocationPermission.always;
  }

  void setOfficeConfig(LatLng? officeLoc, double maxRad) {
    emit(state.copyWith(officeLocation: officeLoc, maxRadius: maxRad));

    // Recalculate radius if we have a current location
    if (state.currentLocation != null) {
      _calculateRadius(state.currentLocation!);
    }
  }

  void _calculateRadius(LatLng currentLocation) {
    if (state.officeLocation == null || state.maxRadius <= 0) {
      emit(state.copyWith(radiusMeters: 0.0, isInRadius: false));
      return;
    }

    final distance = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      state.officeLocation!.latitude,
      state.officeLocation!.longitude,
    );

    emit(
      state.copyWith(
        radiusMeters: distance,
        isInRadius: distance <= state.maxRadius,
      ),
    );
  }

  bool isWithinOfficeRadius() {
    final current = state.currentLocation;
    final office = state.officeLocation;
    if (current == null || office == null) return false;

    final distance = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      office.latitude,
      office.longitude,
    );
    return distance <= state.maxRadius;
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
