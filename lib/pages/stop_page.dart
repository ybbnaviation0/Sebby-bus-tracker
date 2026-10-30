import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../services/gtfs_rt.dart';
import '../services/gtfs_static.dart';

class StopPage extends StatefulWidget {
  final Stop stop;
  const StopPage({super.key, required this.stop});
  @override
  State<StopPage> createState() => _StopPageState();
}

class _StopPageState extends State<StopPage> {
  final _rt = GtfsRtService();
  final _static = GtfsStaticService();
  Timer? _timer;
  List<Arrival> _arrivals = [];
  Map<String, String> _routes = {};
  Map<String, String> _heads = {};
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final arr = await _rt.arrivalsForStop(widget.stop.id);
      final routes = await _static.routeLabels(
          arr.map((a) => a.routeId).whereType<String>().toSet());
      final heads = await _static
          .tripHeadsigns(arr.map((a) => a.tripId).toSet());
      if (!mounted) return;
      setState(() {
        _arrivals = arr;
        _routes = routes;
        _heads = heads;
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

  String _eta(DateTime t) {
    final diff = t.difference(DateTime.now());
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    return DateFormat.Hm().format(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stop.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _arrivals.isEmpty
                  ? const Center(child: Text('No upcoming arrivals right now.'))
                  : ListView.separated(
                      itemCount: _arrivals.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final a = _arrivals[i];
                        final route = a.routeId == null
                            ? '—'
                            : (_routes[a.routeId] ?? a.routeId!);
                        final head = _heads[a.tripId] ?? '';
                        return ListTile(
                          leading: CircleAvatar(child: Text(route)),
                          title: Text(head.isEmpty ? 'Trip ${a.tripId}' : head,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(DateFormat.Hm().format(a.when)),
                          trailing: Text(_eta(a.when),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
    );
  }
}
