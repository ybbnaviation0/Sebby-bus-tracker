import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config.dart';
import '../models.dart';
import '../services/gtfs_rt.dart';
import '../services/gtfs_static.dart';
import 'stop_page.dart';
import 'stop_search_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _map = MapController();
  final _rt = GtfsRtService();
  final _static = GtfsStaticService();

  Timer? _timer;
  Timer? _debounce;
  List<LiveVehicle> _buses = [];
  List<Stop> _stops = [];
  bool _stopsReady = false;
  bool _showStops = true;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      await _static.ensureLoaded();
    } catch (e) {
      debugPrint('Static GTFS load failed: $e');
    }
    if (mounted) setState(() => _stopsReady = true);
    await _refresh();
  }

  Future<void> _refresh() async {
    try {
      final buses = await _rt.vehicles();
      if (!mounted) return;
      setState(() {
        _buses = buses;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _onCamera(MapCamera cam, bool hasGesture) {
    if (!hasGesture) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!_stopsReady || !_showStops) return;
      try {
        final b = cam.visibleBounds;
        final stops = await _static.inBounds(b.south, b.west, b.north, b.east);
        if (mounted) setState(() => _stops = stops);
      } catch (_) {}
    });
  }

  void _openBus(LiveVehicle b) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => ListTile(
        leading: const Icon(Icons.directions_bus),
        title: Text(b.label ?? 'Vehicle ${b.id}'),
        subtitle: Text('Route ${b.routeId ?? 'unknown'}'),
      ),
    );
  }

  List<Marker> get _markers => [
        if (_showStops)
          for (final s in _stops)
            Marker(
              point: LatLng(s.lat, s.lon),
              width: 24,
              height: 24,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => StopPage(stop: s)),
                ),
                child: const Icon(Icons.circle,
                    size: 10, color: Colors.blueAccent),
              ),
            ),
        for (final b in _buses)
          Marker(
            point: LatLng(b.lat, b.lon),
            width: 34,
            height: 34,
            child: GestureDetector(
              onTap: () => _openBus(b),
              child: Transform.rotate(
                angle: (b.bearing ?? 0) * pi / 180,
                child: const Icon(Icons.directions_bus,
                    size: 26, color: Colors.red),
              ),
            ),
          ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sebby Bus Tracker'),
        actions: [
          IconButton(
            tooltip: 'Show stops',
            onPressed: () => setState(() => _showStops = !_showStops),
            icon: Icon(_showStops ? Icons.visibility : Icons.visibility_off),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StopSearchPage()),
            ),
            icon: const Icon(Icons.search),
          ),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: const LatLng(-27.4698, 153.0251),
              initialZoom: 13,
              onPositionChanged: _onCamera,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sebby_bus_tracker',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            left: 8,
            bottom: 8,
            right: 8,
            child: Container(
              color: Colors.white70,
              padding: const EdgeInsets.all(4),
              child: const Text(Config.attribution,
                  style: TextStyle(fontSize: 10)),
            ),
          ),
          if (_loading)
            const Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Feed error: $_error'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
