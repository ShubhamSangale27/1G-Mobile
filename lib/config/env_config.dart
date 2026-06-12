/// Runtime configuration — mirrors Angular `environment.ts` / `environment.prod.ts`.
class EnvConfig {
  const EnvConfig({
    required this.apiBaseUrl,
    this.googleMapsApiKey = '',
    this.isDev = false,
  });

  /// Same Heroku backend URL used by 1G-Frontend.
  static const prod = EnvConfig(
    apiBaseUrl: 'https://og-backend-ec80a37e82c0.herokuapp.com/api',
    isDev: false,
  );

  static const dev = EnvConfig(
    apiBaseUrl: 'https://og-backend-ec80a37e82c0.herokuapp.com/api',
    isDev: true,
  );

  final String apiBaseUrl;
  final String googleMapsApiKey;
  final bool isDev;
}
