class Stop {
  final String id;
  final String? code;
  final String name;
  final double lat;
  final double lon;
  Stop(this.id, this.code, this.name, this.lat, this.lon);
}

class LiveVehicle {
  final String id;
  final String? routeId;
  final String? tripId;
  final String? label;
  final double lat;
  final double lon;
  final double? bearing;
  LiveVehicle(this.id, this.routeId, this.tripId, this.label,
      this.lat, this.lon, this.bearing);
}

class Arrival {
  final String stopId;
  final String tripId;
  final String? routeId;
  final DateTime when;
  final int? delay;
  Arrival(this.stopId, this.tripId, this.routeId, this.when, this.delay);
}
