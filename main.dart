import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:test_drive/leaderboard_page.dart';
import 'package:test_drive/sign_up.dart';
import 'package:test_drive/user.dart';
import 'home_page.dart';
import 'calendar_page.dart';
import 'profile_page.dart';
import 'notifications.dart';
import 'dart:io';
import 'search.dart';

//import 'settings_page.dart';


class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}
//erase this 

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, /////////
      title: 'LVH',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(156, 136, 41, 133),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: TextTheme(
          displayLarge: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
          titleLarge: GoogleFonts.raleway(fontSize: 30, fontStyle: FontStyle.italic),
          bodyMedium: GoogleFonts.spaceGrotesk(),
          displaySmall: GoogleFonts.spaceGrotesk(),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.user, this.org, this.index});
  final String title;
  final ApiGetUser? user;
  final ApiGetOrg? org;
  final int? index;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  int _searchRadius = 100;
  Map<String, Map<String, int>>? _cachedLeaderboardData;
  List<ApiGetUser>? _cachedVolunteerData;

  @override
  void initState() {
    super.initState();
    if (widget.index != null) {
      _selectedIndex = widget.index!;
    }
  }

  List<Widget> get _pages => [
    HomePage(key: homePageKey, user: widget.user, org: widget.org),
    CalendarPage(user: widget.user, org: widget.org, searchRadius: _searchRadius, onRadiusChanged: (radius){
      setState(() {
        _searchRadius = radius;
      });
    }),
    SearchPage(user: widget.user, org: widget.org),
    NotificationsPage(user: widget.user),
    if(widget.user?.userType == 1) LeaderboardPage(
      user: widget.user,
      cachedLeaderboardData: _cachedLeaderboardData,
      onCacheLeaderboard: (data) {
        setState(() {
            _cachedLeaderboardData = data;
          });
      },
      cachedVolunteerData: _cachedVolunteerData,
      onCacheVolunteer: (data) {
        setState(() {
          _cachedVolunteerData = data;
        });
      }),
    ProfilePage(user: widget.user),
    //SettingsPage(user: widget.user),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
        child: GNav(
          gap: 8,
          padding: const EdgeInsets.all(16),
          tabs: [
            const GButton(icon: Icons.home, text: "Home"),
            const GButton(icon: Icons.calendar_month, text: "Calendar"),
            const GButton(icon: Icons.search, text: "Search"),
            const GButton(icon: Icons.notifications, text: "Notifications"),
            if (widget.user?.userType == 1) const GButton(icon: Icons.leaderboard, text: "Leaderboard"),
            const GButton(icon: Icons.person_2_outlined, text: "Profile"),
            //GButton(icon: Icons.settings, text: "Settings"),
          ],
          selectedIndex: _selectedIndex,
          onTabChange: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   title: Text(widget.title),
      // ),
      body: _pages[_selectedIndex],
    );
  }
}
