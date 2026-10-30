class Config {
  // Leave this exactly as is (this is the timetable ZIP)
  static const staticGtfsUrl = 'https://translink.com.au/sites/default/files/assets/resources/SEQ_GTFS.zip';

  // Leave this exactly as is (this is the map)
  static const vehiclePositionsUrl = 'https://gtfsrt.api.translink.com.au/api/realtime/SEQ/VehiclePositions';
  
  // Leave this exactly as is (this is the arrivals)
  static const tripUpdatesUrl = 'https://gtfsrt.api.translink.com.au/api/realtime/SEQ/TripUpdates';

  // Leave this empty until you get the API key
  static const apiKey = '';
  
  // Leave this exactly as is
  static const apiKeyHeader = 'apikey';

  // --- DO NOT DELETE THE REST OF THIS FILE ---

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
