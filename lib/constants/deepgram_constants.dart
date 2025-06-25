class DeepgramConstants {
  static const String apiKey = 'YOUR_DEEPGRAM_API_KEY';
  static const String serverUrl = 'wss://api.deepgram.com/v1/listen';

  static const String defaultModel = 'nova-2';
  static const String defaultLanguage = 'en-US';
  static const String defaultEncoding = 'linear16';
  static const int defaultSampleRate = 16000;
  static const int defaultChannels = 1;
  static const bool defaultSmartFormat = true;
  static const bool defaultInterimResults = true;
  static const bool defaultPunctuate = true;
}
