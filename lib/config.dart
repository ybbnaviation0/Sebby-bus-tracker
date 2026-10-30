class Config {
  // Leave this exactly as is (this is the timetable ZIP)
  static const staticGtfsUrl = 'https://translink.com.au/sites/default/files/assets/resources/SEQ_GTFS.zip';

  // Leave this exactly as is (this is the map)
  static const vehiclePositionsUrl = 'https://gtfsrt.api.translink.com.au/api/realtime/SEQ/VehiclePositions';
  
  // Leave this exactly as is (this is the arrivals)
  static const tripUpdatesUrl = 'https://gtfsrt.api.translink.com.au/api/realtime/SEQ/TripUpdates';

  // ONLY CHANGE THIS LINE with your API key
  static const apiKey = 'YOUR_API_KEY_HERE';
  
  // Leave this exactly as is
  static const apiKeyHeader = '';
