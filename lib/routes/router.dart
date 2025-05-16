import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/models/carpool.dart';
import 'package:inventrack/models/inventory.dart';
import 'package:inventrack/screens/carpool/carpool_detail.dart';
import 'package:inventrack/screens/carpool/carpool_form.dart';
import 'package:inventrack/screens/carpool/carpool_menu.dart';
import 'package:inventrack/screens/carpool/carpool_view.dart';
import 'package:inventrack/screens/carpool/carpoolrequest_detail.dart';
import 'package:inventrack/screens/carpool/carpoolrequest_form.dart';
import 'package:inventrack/screens/carpool/carpoolrequest_view.dart';
import 'package:inventrack/screens/home.dart';
import 'package:inventrack/screens/authscreens/loginpage.dart';
import 'package:inventrack/screens/authscreens/signuppage.dart';
import 'package:inventrack/screens/inventory/inventory_detail.dart';
import 'package:inventrack/screens/inventory/inventory_form.dart';
import 'package:inventrack/screens/inventory/inventory_transactiondetail.dart';
import 'package:inventrack/screens/inventory/inventory_transactionform.dart';
import 'package:inventrack/screens/inventory/inventory_menu.dart';
import 'package:inventrack/screens/inventory/inventory_transactionview.dart';
import 'package:inventrack/screens/inventory/inventory_view.dart';
import 'router_name.dart';

CustomTransitionPage buildTransitionPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );
    },
  );
}

final router = GoRouter(
  redirect: (context, state) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final isLoggedIn = auth.currentUser != null;

    final isAuthPage = [
      '/',
      '/register',
      '/forgotpassword',
      '/resetpassword',
    ].contains(state.uri.path);

    if (!isLoggedIn && !isAuthPage) {
      return "/login";
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: Routes.login,
      pageBuilder: (context, state) =>
          buildTransitionPage(const LoginPage(), state),
    ),
    GoRoute(
      path: '/home',
      name: Routes.home,
      pageBuilder: (context, state) =>
          buildTransitionPage(const HomePage(), state),
      routes: [
        GoRoute(
          path: 'carpool',
          name: Routes.carpoolMenu,
          pageBuilder: (context, state) =>
              buildTransitionPage(const CarpoolMenu(), state),
          routes: [
            GoRoute(
              path: 'form',
              name: Routes.carpoolForm,
              pageBuilder: (context, state) =>
                  buildTransitionPage(const CarpoolForm(), state),
            ),
            GoRoute(
              path: 'view',
              name: Routes.carpoolView,
              pageBuilder: (context, state) =>
                  buildTransitionPage(const CarpoolView(), state),
              routes: [
                GoRoute(
                  path: '/carpoolDetail/:id',
                  name: Routes.carpoolDetail,
                  pageBuilder: (context, state) => buildTransitionPage(
                    CarpoolDetail(
                      state.pathParameters['id'].toString(),
                      state.extra as Carpool,
                    ),
                    state,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'carpoolRequest',
              name: Routes.carpoolRequest,
              pageBuilder: (context, state) =>
                  buildTransitionPage(const RequestCarpool(), state),
            ),
            GoRoute(
              path: 'carpoolViewRequest',
              name: Routes.carpoolViewRequest,
              pageBuilder: (context, state) =>
                  buildTransitionPage(const CarpoolViewRequest(), state),
              routes: [
                GoRoute(
                  path: '/carpoolViewRequestDetail/:id',
                  name: Routes.carpoolViewRequestDetail,
                  pageBuilder: (context, state) => buildTransitionPage(
                    CarpoolRequestDetail(
                      state.pathParameters['id'].toString(),
                      state.extra as Carpool,
                    ),
                    state,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
            path: 'inventory',
            name: Routes.inventoryMenu,
            pageBuilder: (context, state) =>
                buildTransitionPage(const InventoryMenu(), state),
            routes: [
              GoRoute(
                path: 'inventoryForm',
                name: Routes.inventoryForm,
                pageBuilder: (context, state) =>
                    buildTransitionPage(const InventoryForm(), state),
              ),
              GoRoute(
                path: 'inventoryTransactionForm',
                name: Routes.inventoryTransactionForm,
                pageBuilder: (context, state) => buildTransitionPage(
                    InventoryTransactionForm(
                      nomorSerial: state.uri.queryParameters['id'],
                      inventoryItem: state.extra as Inventory?,
                    ),
                    state),
              ),
              GoRoute(
                  path: 'inventoryView',
                  name: Routes.inventoryView,
                  pageBuilder: (context, state) =>
                      buildTransitionPage(const InventoryView(), state),
                  routes: [
                    GoRoute(
                      path: '/inventoryViewDetail/:id',
                      name: Routes.inventoryViewDetail,
                      pageBuilder: (context, state) => buildTransitionPage(
                        InventoryDetail(
                          state.pathParameters['id'].toString(),
                          state.extra as Inventory,
                        ),
                        state,
                      ),
                    ),
                  ]),
              GoRoute(
                  path: 'inventoryTransactionView',
                  name: Routes.inventoryTransactionView,
                  pageBuilder: (context, state) => buildTransitionPage(
                      InventoryTransactionView(
                        serialNumber: state.uri.queryParameters['id'],
                      ),
                      state),
                  routes: [
                    GoRoute(
                        path: 'inventoryTransactionDetail/:id',
                        name: Routes.inventoryTransactionDetail,
                        pageBuilder: (context, state) => buildTransitionPage(
                              InventoryTransactionDetail(
                                state.pathParameters['id'] ?? '',
                                state.extra as Inventory,
                              ),
                              state,
                            )),
                  ]),
            ]),
        GoRoute(
          path: 'register',
          name: Routes.register,
          pageBuilder: (context, state) =>
              buildTransitionPage(const SignUpPage(), state),
        ),
      ],
    ),
  ],
);
