import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:inventrack/models/carpool.dart';
import 'package:inventrack/screens/authscreens/forgotpassword.dart';
import 'package:inventrack/screens/authscreens/resetpasspage.dart';
import 'package:inventrack/screens/carpool/carpool_detail.dart';
import 'package:inventrack/screens/carpool/carpool_form.dart';
import 'package:inventrack/screens/carpool/carpool_menu.dart';
import 'package:inventrack/screens/carpool/carpool_view.dart';
import 'package:inventrack/screens/home.dart';
import 'package:inventrack/screens/information_page.dart';
import 'package:inventrack/screens/inventory_menu.dart';
import 'package:inventrack/screens/authscreens/loginpage.dart';
import 'package:inventrack/screens/scanqr.dart';
import 'package:inventrack/screens/authscreens/signuppage.dart';
import 'router_name.dart';

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
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      name: Routes.register,
      builder: (context, state) => const SignUpPage(),
    ),
    GoRoute(
      path: '/forgotpassword',
      name: Routes.forgotpassword,
      builder: (context, state) => const ForgotPassPage(),
    ),
    GoRoute(
      path: '/resetpassword',
      name: Routes.resetpassword,
      builder: (context, state) {
        return ConfirmResetPasswordPage();
      },
    ),
    GoRoute(
      path: '/home',
      name: Routes.home,
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'carpool',
          name: Routes.carpoolMenu,
          builder: (context, state) => const CarpoolMenu(),
          routes: [
            GoRoute(
              path: 'form',
              name: Routes.carpoolForm,
              builder: (context, state) => const CarpoolForm(),
            ),
            GoRoute(
              path: 'view',
              name: Routes.carpoolView,
              builder: (context, state) => const CarpoolView(),
              routes: [
                GoRoute(
                  path: '/carpoolDetail/:id',
                  name: Routes.carpoolDetail,
                  builder: (context, state) {
                    return CarpoolDetail(
                      state.pathParameters['id'].toString(),
                      state.extra as Carpool,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'inventory',
          name: Routes.inventoryMenu,
          builder: (context, state) => const InventoryMenu(),
        ),
        GoRoute(
          path: 'scanqr',
          name: Routes.scanQR,
          builder: (context, state) => const Scanqr(),
        ),
        GoRoute(
          path: 'information',
          name: Routes.information,
          builder: (context, state) => const InformationPage(),
        ),
      ],
    ),
  ],
);
