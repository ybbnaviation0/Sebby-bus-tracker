import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/gtfs_static.dart';
import 'stop_page.dart';

class StopSearchPage extends StatefulWidget {
  const StopSearchPage({super.key});
  @override
  State<StopSearchPage> createState() => _StopSearchPageState();
}

class _StopSearchPageState extends State<StopSearchPage> {
  final _static = GtfsStaticService();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Stop> _results = [];

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (q.trim().length < 2) {
        setState(() => _results = []);
        return;
      }
      final r = await _static.search(q);
      if (mounted) setState(() => _results = r);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Stop name or stop code',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
      ),
      body: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (_, i) {
          final s = _results[i];
          return ListTile(
            leading: const Icon(Icons.directions_bus),
            title: Text(s.name),
            subtitle: Text('Stop ${s.code ?? s.id}'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StopPage(stop: s)),
            ),
          );
        },
      ),
    );
  }
}
