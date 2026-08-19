import 'package:flutter/material.dart';
import 'package:inventrack/bloc/bloc.dart';
import 'package:inventrack/bloc/bloc_observer.dart';
import 'package:inventrack/data/datasources/auth_remote_data_source.dart';
import 'package:inventrack/data/datasources/carpool_remote_data_source.dart';
import 'package:inventrack/data/datasources/inventory_remote_data_source.dart';
import 'package:inventrack/data/repositories/auth_repository_impl.dart';
import 'package:inventrack/data/repositories/carpool_repository_impl.dart';
import 'package:inventrack/data/repositories/inventory_repository_impl.dart';
import 'package:inventrack/domain/repositories/auth_repository.dart';
import 'package:inventrack/domain/repositories/carpool_repository.dart';
import 'package:inventrack/domain/repositories/inventory_repository.dart';
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

  final AuthRepository authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(),
  );

  final InventoryRepository inventoryRepository = InventoryRepositoryImpl(
    remoteDataSource: InventoryRemoteDataSourceImpl(),
  );

  final CarpoolRepository carpoolRepository = CarpoolRepositoryImpl(
    remoteDataSource: CarpoolRemoteDataSourceImpl(),
  );

  runApp(Inventrack(
    authRepository: authRepository,
    inventoryRepository: inventoryRepository,
    carpoolRepository: carpoolRepository,
  ));
}

class Inventrack extends StatelessWidget {
  final AuthRepository authRepository;
  final InventoryRepository inventoryRepository;
  final CarpoolRepository carpoolRepository;

  const Inventrack({
    super.key,
    required this.authRepository,
    required this.inventoryRepository,
    required this.carpoolRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authRepository: authRepository),
        ),
        BlocProvider<CarpoolBloc>(
          create: (context) =>
              CarpoolBloc(carpoolRepository: carpoolRepository),
        ),
        BlocProvider<InventoryBloc>(
          create: (context) =>
              InventoryBloc(inventoryRepository: inventoryRepository),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }
}
