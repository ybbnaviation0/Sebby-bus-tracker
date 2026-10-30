import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';
import '../gen/gtfs-realtime.pb.dart' as rt;

class GtfsRtService {
  Future<rt.FeedMessage> _fetch(String url) async {
    final res = await http.get(Config.withKey(url), headers: Config.headers);
    if (res.statusCode != 200) {
      throw Exception('Feed HTTP ${res.statusCode}');
    }
    return rt.FeedMessage.fromBuffer(res.bodyBytes);
  }

  Future<List<LiveVehicle>> vehicles() async {
    final feed = await _fetch(Config.vehiclePositionsUrl);
    final out = <LiveVehicle>[];
    for (final e in feed.entity) {
      if (!e.hasVehicle()) continue;
      final v = e.vehicle;
      if (!v.hasPosition()) continue;
      final hasTrip = v.hasTrip();
      out.add(LiveVehicle(
        e.id,
        hasTrip && v.trip.hasRouteId() ? v.trip.routeId : null,
        hasTrip && v.trip.hasTripId() ? v.trip.tripId : null,
        v.hasLabel()
            ? v.label
            : (v.hasVehicleId() ? v.vehicleId : null),
        v.position.latitude.toDouble(),
        v.position.longitude.toDouble(),
        v.hasBearing() ? v.position.bearing.toDouble() : null,
      ));
    }
    return out;
  }

  Future<List<Arrival>> arrivalsForStop(String stopId) async {
    final feed = await _fetch(Config.tripUpdatesUrl);
    final cutoff = DateTime.now().subtract(const Duration(minutes: 1));
    final out = <Arrival>[];
    for (final e in feed.entity) {
      if (!e.hasTripUpdate()) continue;
      final tu = e.tripUpdate;
      final hasTrip = tu.hasTrip();
      final routeId = hasTrip && tu.trip.hasRouteId() ? tu.trip.routeId : null;
      final tripId = hasTrip && tu.trip.hasTripId() ? tu.trip.tripId : e.id;
      for (final stu in tu.stopTimeUpdate) {
        if (!stu.hasStopId() || stu.stopId != stopId) continue;
        final ev = stu.hasArrival()
            ? stu.arrival
            : (stu.hasDeparture() ? stu.departure : null);
        if (ev == null || !ev.hasTime()) continue;
        final when = DateTime.fromMillisecondsSinceEpoch(ev.time.toInt() * 1000);
        if (when.isBefore(cutoff)) continue;
        out.add(Arrival(stopId, tripId, routeId, when,
            ev.hasDelay() ? ev.delay.toInt() : null));
      }
    }
    out.sort((a, b) => a.when.compareTo(b.when));
    return out.take(40).toList();
  }
}
