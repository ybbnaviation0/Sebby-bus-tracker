import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../config.dart';
import '../models.dart';

class GtfsStaticService {
  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'sebby_gtfs.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE stops(stop_id TEXT PRIMARY KEY, '
            'code TEXT, name TEXT, lat REAL, lon REAL)');
        await db.execute('CREATE INDEX idx_stops_name ON stops(name)');
        await db.execute('CREATE TABLE routes(route_id TEXT PRIMARY KEY, '
            'short TEXT, long TEXT)');
        await db.execute('CREATE TABLE trips(trip_id TEXT PRIMARY KEY, '
            'route_id TEXT, headsign TEXT)');
      },
    );
    return _db!;
  }

  Future<void> ensureLoaded() async {
    final db = await _open();
    final n = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM stops')) ??
        0;
    if (n > 0) return;

    final res = await http.get(Uri.parse(Config.staticGtfsUrl));
    if (res.statusCode != 200) {
      throw Exception('Static GTFS HTTP ${res.statusCode}');
    }
    final archive = ZipDecoder().decodeBytes(res.bodyBytes);

    await _ingest(archive, 'stops.txt', (h, r, b) {
      final id = _s(r, h, 'stop_id');
      if (id == null) return;
      b.insert(
        'stops',
        {
          'stop_id': id,
          'code': _s(r, h, 'stop_code'),
          'name': _s(r, h, 'stop_name') ?? '',
          'lat': double.tryParse(_s(r, h, 'stop_lat') ?? ''),
          'lon': double.tryParse(_s(r, h, 'stop_lon') ?? ''),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    await _ingest(archive, 'routes.txt', (h, r, b) {
      final id = _s(r, h, 'route_id');
      if (id == null) return;
      b.insert(
        'routes',
        {
          'route_id': id,
          'short': _s(r, h, 'route_short_name'),
          'long': _s(r, h, 'route_long_name'),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    await _ingest(archive, 'trips.txt', (h, r, b) {
      final id = _s(r, h, 'trip_id');
      if (id == null) return;
      b.insert(
        'trips',
        {
          'trip_id': id,
          'route_id': _s(r, h, 'route_id'),
          'headsign': _s(r, h, 'trip_headsign'),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> _ingest(
    Archive archive,
    String name,
    void Function(Map<String, int>, List<dynamic>, Batch) add,
  ) async {
    final file = archive.files.firstWhere(
      (f) => f.name == name || f.name.endsWith('/$name'),
      orElse: () => throw Exception('$name not found in GTFS zip'),
    );
    final db = await _open();
    final text = utf8.decode(file.content as List<int>, allowMalformed: true);
    Map<String, int>? header;
    var batch = db.batch();
    var count = 0;
    for (final line in const LineSplitter().convert(text)) {
      if (line.trim().isEmpty) continue;
      final row =
          const CsvToListConverter(shouldParseNumbers: false).convert(line).first;
      if (header == null) {
        header = {for (var i = 0; i < row.length; i++) row[i].toString(): i};
        continue;
      }
      add(header, row, batch);
      if (++count % 5000 == 0) {
        await batch.commit(noResult: true);
        batch = db.batch();
      }
    }
    await batch.commit(noResult: true);
  }

  String? _s(List<dynamic> row, Map<String, int> h, String key) {
    final i = h[key];
    if (i == null || i >= row.length) return null;
    final v = row[i]?.toString().trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<List<Stop>> search(String q) async {
    final db = await _open();
    final like = '%${q.trim()}%';
    final rows = await db.query('stops',
        where: 'name LIKE ? OR code LIKE ?',
        whereArgs: [like, like],
        limit: 30);
    return _toStops(rows);
  }

  Future<List<Stop>> inBounds(
      double south, double west, double north, double east) async {
    final db = await _open();
    final rows = await db.query('stops',
        where: 'lat BETWEEN ? AND ? AND lon BETWEEN ? AND ?',
        whereArgs: [south, north, west, east],
        limit: 300);
    return _toStops(rows);
  }

  List<Stop> _toStops(List<Map<String, Object?>> rows) => [
        for (final r in rows)
          if (r['lat'] != null && r['lon'] != null)
            Stop(
              r['stop_id'] as String,
              r['code'] as String?,
              (r['name'] as String?) ?? '',
              (r['lat'] as num).toDouble(),
              (r['lon'] as num).toDouble(),
            )
      ];

  Future<Map<String, String>> routeLabels(Set<String> ids) async {
    if (ids.isEmpty) return {};
    final db = await _open();
    final q = List.filled(ids.length, '?').join(',');
    final rows = await db.query('routes',
        columns: ['route_id', 'short', 'long'],
        where: 'route_id IN ($q)',
        whereArgs: ids.toList());
    return {
      for (final r in rows)
        r['route_id'] as String: ((r['short'] as String?)?.isNotEmpty ?? false)
            ? r['short'] as String
            : ((r['long'] as String?) ?? '')
    };
  }

  Future<Map<String, String>> tripHeadsigns(Set<String> ids) async {
    if (ids.isEmpty) return {};
    final db = await _open();
    final q = List.filled(ids.length, '?').join(',');
    final rows = await db.query('trips',
        columns: ['trip_id', 'headsign'],
        where: 'trip_id IN ($q)',
        whereArgs: ids.toList());
    return {
      for (final r in rows)
        r['trip_id'] as String: (r['headsign'] as String?) ?? ''
    };
  }
}
