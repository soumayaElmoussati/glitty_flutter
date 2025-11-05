class Env {
 // static const String baseUrl = 'https://glitty.fr';

    static const String baseUrl = 'http://localhost:3000';

  // Vous pouvez ajouter d'autres variables d'environnement ici
  static const String appName = 'Glitty';
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
}
