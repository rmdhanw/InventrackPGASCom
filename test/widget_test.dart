import 'package:flutter_test/flutter_test.dart';
import 'package:inventrack/data/datasources/auth_remote_data_source.dart';
import 'package:inventrack/data/datasources/carpool_remote_data_source.dart';
import 'package:inventrack/data/datasources/inventory_remote_data_source.dart';
import 'package:inventrack/data/repositories/auth_repository_impl.dart';
import 'package:inventrack/data/repositories/carpool_repository_impl.dart';
import 'package:inventrack/data/repositories/inventory_repository_impl.dart';
import 'package:inventrack/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(),
    );
    final inventoryRepository = InventoryRepositoryImpl(
      remoteDataSource: InventoryRemoteDataSourceImpl(),
    );
    final carpoolRepository = CarpoolRepositoryImpl(
      remoteDataSource: CarpoolRemoteDataSourceImpl(),
    );

    await tester.pumpWidget(Inventrack(
      authRepository: authRepository,
      inventoryRepository: inventoryRepository,
      carpoolRepository: carpoolRepository,
    ));
  });
}
