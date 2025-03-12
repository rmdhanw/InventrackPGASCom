import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
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
    FirebaseAuth auth = FirebaseAuth.instance;
    if (auth.currentUser == null &&
        state.uri.toString() != "/login" &&
        state.uri.toString() != "/register") {
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
              path: 'carpoolform',
              name: Routes.carpoolForm,
              builder: (context, state) => CarpoolForm(),
            ),
            GoRoute(
              path: 'carpoolview',
              name: Routes.carpoolView,
              builder: (context, state) => const CarpoolView(),
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
