/// Build flavor for development vs production environments.
enum AppFlavor {
  development,
  production,
}

extension AppFlavorX on AppFlavor {
  String get displayName => switch (this) {
        AppFlavor.development => 'Haven NYC Dev',
        AppFlavor.production => 'Haven NYC',
      };

  bool get isDevelopment => this == AppFlavor.development;

  bool get isProduction => this == AppFlavor.production;
}
