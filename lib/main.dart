import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'api/api_client.dart';
import 'api/hospitals_api.dart';
import 'api/patient_api.dart';
import 'auth/auth_controller.dart';
import 'auth/change_password_screen.dart';
import 'auth/login_screen.dart';
import 'screens/home_shell.dart';
import 'theme.dart';
import 'widgets/lafia_logo.dart';

void main() {
  // Le stockage sécurisé est lu avant le premier affichage.
  WidgetsFlutterBinding.ensureInitialized();
  final client = ApiClient();
  final auth = AuthController(client)..restore();
  runApp(LafiaSnaApp(api: HospitalsApi(client), patientApi: PatientApi(client), auth: auth));
}

class LafiaSnaApp extends StatelessWidget {
  const LafiaSnaApp({super.key, required this.api, required this.patientApi, required this.auth});

  final HospitalsApi api;
  final PatientApi patientApi;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: auth,
      child: PatientApiScope(
        api: patientApi,
        child: MaterialApp(
          title: 'Lafia Sna',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          // Calendrier, horloge et textes système en français.
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: _Root(api: api),
        ),
      ),
    );
  }
}

/// Premier écran selon la session : connexion, changement de mot de passe provisoire ou hôpitaux.
class _Root extends StatelessWidget {
  const _Root({required this.api});

  final HospitalsApi api;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (!auth.isReady) {
      return const Scaffold(body: Center(child: LafiaLogo(size: 84)));
    }
    if (auth.user?.mustChangePassword ?? false) return const ChangePasswordScreen();
    if (auth.shouldAskToLogin) return const LoginScreen();
    return HomeShell(api: api);
  }
}
