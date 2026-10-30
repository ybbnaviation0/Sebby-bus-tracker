class Config {
  // Paste the official South East Queensland static GTFS zip URL.
  static const staticGtfsUrl = 'REPLACE_ME_STATIC_GTFS_ZIP_URL';

  // Paste the official GTFS-Realtime endpoints.
  static const vehiclePositionsUrl = 'REPLACE_ME_VEHICLE_POSITIONS_URL';
  static const tripUpdatesUrl = 'REPLACE_ME_TRIP_UPDATES_URL';

  // API key, if the portal requires one.
  static const apiKey = '';
  // Set to e.g. 'apikey' if the portal wants a header instead of ?api_key=
  static const apiKeyHeader = '';

  static Map<String, String> get headers => {
        'Accept': 'application/x-protobuf',
        if (apiKeyHeader.isNotEmpty && apiKey.isNotEmpty) apiKeyHeader: apiKey,
      };

  static Uri withKey(String url) {
    final u = Uri.parse(url);
    if (apiKey.isEmpty || apiKeyHeader.isNotEmpty) return u;
    return u.replace(queryParameters: {...u.queryParameters, 'api_key': apiKey});
  }

  static const attribution =
      'Transit data © TransLink / Queensland Government. Unofficial app.';
}
