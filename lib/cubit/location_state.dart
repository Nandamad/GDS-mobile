import 'package:latlong2/latlong.dart';

class LocationState {
  final LatLng? currentLocation;
  final double gpsAccuracy;
  final bool isMocked;
  final LatLng? officeLocation;
  final double maxRadius;
  final double radiusMeters;
  final bool isInRadius;
  final String? errorMessage;

  LocationState({
    this.currentLocation,
    this.gpsAccuracy = 0.0,
    this.isMocked = false,
    this.officeLocation,
    this.maxRadius = 0.0,
    this.radiusMeters = 0.0,
    this.isInRadius = false,
    this.errorMessage,
  });

  LocationState copyWith({
    LatLng? currentLocation,
    double? gpsAccuracy,
    bool? isMocked,
    LatLng? officeLocation,
    double? maxRadius,
    double? radiusMeters,
    bool? isInRadius,
    String? errorMessage,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      isMocked: isMocked ?? this.isMocked,
      officeLocation: officeLocation ?? this.officeLocation,
      maxRadius: maxRadius ?? this.maxRadius,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      isInRadius: isInRadius ?? this.isInRadius,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
