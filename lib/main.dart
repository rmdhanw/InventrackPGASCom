import 'package:flutter/material.dart';
import 'package:inventrack/bloc/bloc.dart';
import 'package:inventrack/bloc/bloc_observer.dart';
import 'package:inventrack/routes/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  Bloc.observer = AppBlocObserver();
  runApp(const Inventrack());
}

class Inventrack extends StatelessWidget {
  const Inventrack({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(),
        ),
        BlocProvider<ProductBloc>(
          create: (context) => ProductBloc(),
        ),
        BlocProvider<CarpoolBloc>(
          create: (context) => CarpoolBloc(),
        ),
        BlocProvider<InventoryBloc>(
          create: (context) => InventoryBloc(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }
}
