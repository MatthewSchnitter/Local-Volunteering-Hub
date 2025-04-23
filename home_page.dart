import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test_drive/add_event_page.dart';
import 'user.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart'; // Import geocoding package
import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';
import 'base_url.dart';
import 'package:geolocator/geolocator.dart'; 
import 'utils.dart';
import 'dart:convert';
//import 'package:image_picker/image_picker.dart';


final GlobalKey<_HomePageState> homePageKey = GlobalKey<_HomePageState>();

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.user, this.org,});
  final ApiGetUser? user;
  final ApiGetOrg? org;

  
  
  @override
  _HomePageState createState() => _HomePageState();
}
 //use if date format is not DD/MM/YYYY or MM-DD-YYYY
DateTime parseCustomDate(String date) {
  try {
    //print('Parsing date: "$date"'); // Debugging print to check the input - delete this 

    // i will trim the date to avoid extra spaces and split by '/'
    final parts = date.trim().split('/');
    if (parts.length == 3) {
      // check that month, day, and year are valid integers
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      // Check for valid month and day ranges
      if (month < 1 || month > 12 || day < 1 || day > 31) {
        throw const FormatException("Invalid month or day value");
      }

      return DateTime(year, month, day);
    } else {
      throw const FormatException("Invalid date format");
    }
  } catch (e) {
    print("Error parsing date: $e");
    return DateTime(1900); // Return default date on failure
  }
}
class _HomePageState extends State<HomePage>{
  
  List<Event> userEvents = [];
  List<Event> favoriteEvents = [];
  List<Event> regEvents = [];
  List<Event> mapEvents = [];
  List<Event> recEvents = [];
  bool isLoading = true;
  bool isLoadingFavorites = true;
  bool isLoadingUserEvents = true;
  bool isLoadingNearbyEvents = true;
  bool isLoadingRecommendations = true;
  bool isLoadingRegisteredEvents = true;
  bool eventsLoaded = false;
  Map<int, bool> favoriteEventStatus = {};
  int _selectedTab = 0;
  String baseUrl = UrlHelper.getBaseUrl(); //get base url for all api calls here

  //google maps stuff
  GoogleMapController? mapController;
  //late GoogleMapController mapController;

  
  final TextEditingController _zipCodeController = TextEditingController();
  LatLng _center = const LatLng(37.7749, -122.4194); // Default location: utah zipcode
  final Set<Marker> _markers = {}; // Set to store markers that we will need
  String googleApiKey = 'AIzaSyAnW2T_l61Fev-HntHxJQ8E3I1zneu_i4w'; //  Google API Key

  // this will be called when the map is created
 void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    //fetchEvents();  
    _getCurrentLocation();
  }
  //google maps stuff

  @override
  void initState() {
    super.initState();
    fetchEvents();
    final String? userZip = widget.user?.zip;

    _zipCodeController.text = userZip!;
    
   
  }


  Future<void> _moveMapToZipCode(String zipCode) async {
    try {
      if (kIsWeb) {
        // using google maps geocoding API for web
        final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$zipCode&key=$googleApiKey';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final location = jsonResponse['results'][0]['geometry']['location'];
          final LatLng newCenter = LatLng(location['lat'], location['lng']);
          _center = newCenter;
          //_addMarker(_center, 'Location: $zipCode');
          if (mapController != null) {
            mapController!.animateCamera(CameraUpdate.newLatLng(_center));
          }
        } else {
          throw Exception('Failed to load location');
        }
      } else {
        // using the existing method for Android/iOS
        List<Location> locations = await locationFromAddress(zipCode);
        if (locations.isNotEmpty) {
          _center = LatLng(locations.first.latitude, locations.first.longitude);
          //_addMarkerNotEvent(_center, 'Location: $zipCode');
          if (mapController != null) {
            mapController!.animateCamera(CameraUpdate.newLatLng(_center));
          }
        }
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid zip code. Please try again.')),
      );
    }
  }




  // Get current location and move map to that location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // just in care test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    // once permission is granted, get the user's current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _center = LatLng(position.latitude, position.longitude);

    // Reverse geocode to get the zip code of the current location
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        String? localZipCode = placemarks.first.postalCode;
        if (localZipCode != null) {
          _zipCodeController.text = localZipCode; 
          _moveMapToZipCode(localZipCode);
        }
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
    }

    // Move the map to the current location and add a marker where we are at in real time
    //_addMarkerNotEvent(_center, 'Current Location');

    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(_center),
      );
    }
  }
  
   // Function to add markers
  void _addMarker(LatLng position, String description) {
    final Marker marker = Marker(
      markerId: MarkerId(description),
      position: position,
      infoWindow: InfoWindow(
        title: description,
      ),
    );

    if (mounted) {
    setState(() {
      _markers.add(marker);
      });
    }
  }

  // Function to add markers
  void _addMarkerNotEvent(LatLng position, String description) {
    final Marker marker = Marker(
      markerId: MarkerId(description),
      position: position,
      infoWindow: InfoWindow(
        title: description,
      ),
    );

    if (mounted) {
    setState(() {
      _markers.add(marker);
      });
    }
  }

  String sanitizeAddress(String address) {
    return address.replaceAll(RegExp(r'\s*,\s*'), ', ').trim();  // Trim spaces around commas
  }

  bool isValidAddress(String? street, String? city, String? state, String? zip, String? countryCode) {
  return street != null && street.isNotEmpty &&
         city != null && city.isNotEmpty &&
         state != null && state.isNotEmpty &&
         zip != null && zip.isNotEmpty &&
         countryCode != null && countryCode.isNotEmpty;
}

Future<void> _addMarkerForAddress(String address) async {
  try {
    // Geocode the address to get latitude and longitude
    List<Location> locations = await locationFromAddress(address);
    if (locations.isNotEmpty) {
      Location location = locations.first;
      LatLng latLng = LatLng(location.latitude, location.longitude);

      // Use the existing helper function to add a marker at the address location
      _addMarkerNotEvent(latLng, address); // Using existing helper function
      
      // Move the map to the marker location
      if (mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(latLng));
      }
    }
  } catch (e) {
    print('Error adding marker for address: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to add marker for the address.')),
    );
  }
}


  void _addMarkerForEvent(Event event) async {
    try {
      String fullAddress = sanitizeAddress('${event.street}, ${event.city}, ${event.state}, ${event.zip}, ${event.countryCode}');
      final encodedAddress = Uri.encodeFull(fullAddress);
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$googleApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'OK' && jsonResponse['results'].isNotEmpty) {
          final location = jsonResponse['results'][0]['geometry']['location'];
          final LatLng eventLatLng = LatLng(location['lat'], location['lng']);

          // Create the marker with an onTap function
          final Marker marker = Marker(
            markerId: MarkerId(event.id.toString()),
            position: eventLatLng,
            infoWindow: InfoWindow(
              title: event.name,
              snippet: event.city, // or any other detail you want to show
            ),
            onTap: () {
              showEventDetails(context, event, widget.user, widget.org, isRegisteredEvent: false);
            },
          );
          if(mounted){
          setState(() {
            _markers.add(marker);
          });}
        } else {
          print('Error: No valid location found for event ${event.name}');
        }
      } else {
        print('Error: Failed to get geocoding data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding marker for event ${event.name}: $e');
    }
  }


  Color generateColorFromEventName(String eventName) {
  if (eventName.isEmpty) {
    // Default color if the name is empty
    return const Color.fromARGB(255, 240, 200, 240); // Light pastel purple
  }

  // Get the first letter of the event name
  String firstLetter = eventName[0].toUpperCase();

  // Map the first letter to a predictable range using ASCII
  int asciiValue = firstLetter.codeUnitAt(0);

  // Generate colors based on scaled ranges of the ASCII value
  int red = 200 + (asciiValue * 3) % 56;   // Range: 200-255
  int green = 170 + (asciiValue * 2) % 50; // Range: 170-220
  int blue = 220 + (asciiValue * 5) % 36;  // Range: 220-255

  return Color.fromARGB(255, red, green, blue);
}

  void fetchEvents() async {
    final userId = widget.user?.idNumber;

    if (mounted) {
      setState(() {
        isLoadingFavorites = true;
        isLoadingUserEvents = true;
        isLoadingNearbyEvents = true;
        isLoadingRegisteredEvents = true;
        isLoadingRecommendations = true;
      });
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Fetch and process events independently
    fetchUserEvents(userId, today);
    fetchFavoriteEvents(userId, today);
    fetchRegisteredEvents(userId, today);
    fetchRecommendedEvents(userId, today);
    getEventsInRadius(500); //can change radius
  }

  Future<void> getEventsInRadius(int radius) async {
    try {
      //print("radius: $radius");
      String userZip = widget.user?.zip ?? 'default-zip'; // i will provide  a default value if zip is null
      var url = Uri.parse("$baseUrl/api/Event/GetEventsInGivenRadius/$userZip/$radius");
      
      
      var response = await http.get(url);
      print("${response.statusCode}");
      if (response.statusCode == 200) {

        mapEvents = welcomeFromJson(response.body);
        isLoadingNearbyEvents = false;
      }
    } catch (e) {
      print(e.toString());
    }
  }


  Future<void> fetchUserEvents(int? userId, DateTime today) async {
    try {
      final events = await getUserEvents(userId);
      final filteredEvents = events
          .where((event) {
            final eventDate = parseCustomDate(event.date);
            return eventDate.isAfter(today) || eventDate.isAtSameMomentAs(today);
          })
          .toList()
        ..sort((a, b) => parseCustomDate(a.date).compareTo(parseCustomDate(b.date)));

      if (mounted) {
        setState(() {
          userEvents = filteredEvents;
          isLoadingUserEvents = false;
        });
      }
    } catch (e) {
      print('Error fetching user events: $e');
      if (mounted) {
        setState(() {
          isLoadingUserEvents = false;
        });
      }
    }
  }

  Future<void> fetchFavoriteEvents(int? userId, DateTime today) async {
    try {
      final events = await getFavoriteEvents(userId);
      final filteredEvents = events
          .where((event) {
            final eventDate = parseCustomDate(event.date);
            return eventDate.isAfter(today) || eventDate.isAtSameMomentAs(today);
          })
          .toList()
        ..sort((a, b) => parseCustomDate(a.date).compareTo(parseCustomDate(b.date)));

      if (mounted) {
        setState(() {
          favoriteEvents = filteredEvents;
          isLoadingFavorites = false;
        });
      }
    } catch (e) {
      print('Error fetching favorite events: $e');
      if (mounted) {
        setState(() {
          isLoadingFavorites = false;
        });
      }
    }
  }

  void refereshLikesAndRegs(){
    if(mounted){
      setState(() {
        print("in refresh");
        fetchFavoriteEvents(widget.user!.idNumber, DateTime.now());
        fetchRegisteredEvents(widget.user!.idNumber, DateTime.now());
      });
    }
  }

  Future<void> fetchRegisteredEvents(int? userId, DateTime today) async {
    try {
      final events = await getRegisteredEvents(userId);

      final filteredEvents = events
          .where((event) {
            final eventDate = parseCustomDate(event.date);
            return eventDate.isAfter(today) || eventDate.isAtSameMomentAs(today);
          })
          .toList()
        ..sort((a, b) => parseCustomDate(a.date).compareTo(parseCustomDate(b.date)));

      if (mounted) {
        setState(() {
          regEvents = filteredEvents;
          isLoadingRegisteredEvents = false;
        });
      }
    } catch (e) {
      print('Error fetching registered events: $e');
      if (mounted) {
        setState(() {
          isLoadingRegisteredEvents = false;
        });
      }
    }
  }

  Future<void> fetchRecommendedEvents(int? userId, DateTime today) async {
    try {
      final events = await getRecommendedEvents(userId);
      final filteredEvents = events
          .where((event) {
            final eventDate = parseCustomDate(event.date);
            return eventDate.isAfter(today) || eventDate.isAtSameMomentAs(today);
          })
          .toList()
        ..sort((a, b) => parseCustomDate(a.date).compareTo(parseCustomDate(b.date)));

      if (mounted) {
        setState(() {
          recEvents = filteredEvents;
          isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      print('Error fetching recommended events: $e');
      if (mounted) {
        setState(() {
          isLoadingRecommendations = false;
        });
      }
    }
  }

  Future<List<Event>> getUserEvents(int? userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/Event/GetEventsByHost?hostId=$userId'));
      if (response.statusCode == 200) {
        return welcomeFromJson(response.body);  
        
      } else {
        print('Failed to load user events. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user events: $e');
    }
    return [];
  }


  Future<List<Event>> getRecommendedEvents(int? userId) async {
    if (userId == null) return [];
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/Event/GetEventRecommendations?userId=$userId'));
      if (response.statusCode == 200) {
        return welcomeFromJson(response.body);
        
      } else {
        print('Failed to load user events. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user events: $e');
    }
    return [];
  }

  Future<List<Event>> getRegisteredEvents(int? userId) async {
    if (userId == null) return [];
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/Volunteer/GetVolunteerRegisteredEvents/$userId'));
      if (response.statusCode == 200) {
        return welcomeFromJson(response.body);  
      } else {
        print('Failed to load user events. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user events: $e');
    }
    return [];
  }


  Future<List<Event>> getFavoriteEvents(int? userId) async {
    if (userId == null) return [];

    try {
      final response = await http.get(Uri.parse("$baseUrl/api/Event/GetUsersFavoritedEvents?userId=$userId"));
      if (response.statusCode == 200) {
        
        final evt = welcomeFromJson(response.body); // Ensure welcomeFromJson is correct
        for(var event in evt){
          favoriteEventStatus[event.id] = true;
        }
        return evt;
      } else {
        print('Failed to load favorite events. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching favorite events: $e');
    }
    return [];
  }

  void updateFavoriteStatus(int eventId, bool isFavorite) {
    if(mounted){setState(() {
      favoriteEventStatus[eventId] = isFavorite;
    });}
  }

  Widget _buildTab({required IconData icon, required String label, required int index}) {
    return GestureDetector(
      onTap: () {
        if(mounted){setState(() {
          _selectedTab = index;
        });}
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(30), 
          color: _selectedTab == index ? Colors.purple.withOpacity(0.1) : Colors.transparent, 
        ),
        padding: const EdgeInsets.all(16), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.white,
            ),
            const SizedBox(height: 4), 
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Text("Welcome, ${widget.user?.userName}",
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 32),
                        _buildTab(
                          icon: Icons.person_outlined,
                          label: 'Created Events',
                          index: 0,
                        ),
                        const SizedBox(width: 32),
                        _buildTab(
                          icon: Icons.recommend,
                          label: 'Recommended',
                          index: 3,
                        ),
                        
                        
                        const SizedBox(width: 32),
                        _buildTab(
                          icon: Icons.travel_explore,
                          label: 'Explore',
                          index: 4,
                        ),
                        if (widget.user?.userType == 1) ...[ //here we check if the user is a vol or org, orgs dont have registered events
                          const SizedBox(width: 32),
                          _buildTab(
                            icon: Icons.app_registration_outlined,
                            label: 'Planned Events',
                            index: 1,
                          ),
                          const SizedBox(width: 32),
                          _buildTab(
                            icon: Icons.bookmark,
                            label: 'Bookmarks',
                            index: 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //loading wheel widget
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  
  //method to conditionally render content based on selected tab
  List<Widget> _buildContent() {
    if(_selectedTab == 0){
      return isLoadingUserEvents 
        ? [_buildLoadingIndicator()] 
        : _buildUserEvents();
    }
    else if (_selectedTab == 2) {
      return isLoadingFavorites 
        ? [_buildLoadingIndicator()] 
        : _buildBookmarkedEvents();
    } else if (_selectedTab == 3) {
      return isLoadingRecommendations 
      ? [_buildLoadingIndicator()]
      : _buildRecommendedEvents();
    } else if (_selectedTab == 4) {
      return isLoadingNearbyEvents 
        ? [_buildLoadingIndicator()] 
        : _buildNearbyEvents();
    } else {
      return isLoadingRegisteredEvents 
        ? [_buildLoadingIndicator()] 
        : _buildRegisteredEvents();
    }
  }


  List<Widget> _buildRecommendedEvents() {
  return [
    const Text(
      'Recommended Events',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color.fromRGBO(210, 153, 227, 1),
      ),
    ),
    const Text(
      '*Recommended Events are based on user preferences and your distance from events*',
      style: TextStyle(
        fontSize: 13,
        color: Colors.white,
      ),
    ),
    const SizedBox(height: 10),
    SizedBox(
      height: recEvents.isEmpty ? 200 : recEvents.length * 220.0,
      child: recEvents.isEmpty
          ? const Center(
              child: Text(
                "No recommended events available!",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: recEvents.length,
              itemBuilder: (context, index) {
                final event = recEvents[index];
                return GestureDetector(
                  onTap: () => showEventDetails(context, event, widget.user, widget.org, isRegisteredEvent: false),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: generateColorFromEventName(event.name),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        event.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      FittedBox(
                                        child: Row(
                                          children: <Widget>[
                                            const Icon(Icons.location_on),
                                            const SizedBox(width: 5),
                                            Text(
                                              event.city,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.date_range_sharp),
                                        Text(
                                        event.date.toUpperCase(),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ]
                                  ),
                                ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    ),
  ];
}


  List<Widget> _buildBookmarkedEvents() {
  return [
    const Text(
      'Bookmarked Events',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color.fromRGBO(210, 153, 227, 1),
      ),
    ),
    const SizedBox(height: 10),
    SizedBox(
      height: favoriteEvents.isEmpty ? 200 : favoriteEvents.length * 220.0, 
      child: favoriteEvents.isEmpty
          ? const Center(
              child: Text(
                'No saved events yet!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: favoriteEvents.length,
              itemBuilder: (context, index) {
                final event = favoriteEvents[index];
                return GestureDetector(
                  onTap: () => showEventDetails(context, event, widget.user, widget.org, isRegisteredEvent: false),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), 
                    decoration: BoxDecoration(
                      color: generateColorFromEventName(event.name),
                      borderRadius: BorderRadius.circular(24), 
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20), // Inner padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // ClipRRect(
                          //   borderRadius: BorderRadius.all(Radius.circular(30)),
                          //   child: Image.asset(
                          //     event.imagePath, // Assuming each event has an imagePath
                          //     height: 150,
                          //     fit: BoxFit.fitWidth,
                          //   ),
                          // ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        event.name, 
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black, 
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      FittedBox(
                                        child: Row(
                                          children: <Widget>[
                                            const Icon(Icons.location_on),
                                            const SizedBox(width: 5),
                                            Text(
                                              event.city, 
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black, 
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      event.date.toUpperCase(), 
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black, 
                                      ),
                                    )
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    ),
  ];
}

 List<Widget> _buildUserEvents() {
  return [
    Stack(
      children: [
        // "Your Events" title and Add Event button aligned to the right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Events',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(210, 153, 227, 1),
              ),
            ),
            FloatingActionButton(
              mini: true,
              onPressed: () async {
                final eventDetails = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddEventPage(isEditing: false, user: widget.user),
                  ),
                );
                if (eventDetails != null) {
                  await getUserEvents(widget.user?.idNumber);
                }
              },
              tooltip: 'Add Event',
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.only(top: 40), 
          child: userEvents.isEmpty
              ? const Center(
                  child: Text(
                    "No events posted!",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), //might need to change, this. TODO: testing on this
                  itemCount: userEvents.length,
                  itemBuilder: (context, index) {
                    final event = userEvents[index];
                    return GestureDetector(
                      onTap: () => showEventDetails(context, event, widget.user, widget.org, isRegisteredEvent: false),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: generateColorFromEventName(event.name),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            event.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          FittedBox(
                                            child: Row(
                                              children: <Widget>[
                                                const Icon(Icons.location_on),
                                                const SizedBox(width: 5),
                                                Text(
                                                  event.city,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          event.date.toUpperCase(),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  ];
}



  List<Widget> _buildRegisteredEvents() {
    return [
      const Text(
        'Events you plan on attending',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color.fromRGBO(210, 153, 227, 1),
        ),
      ),
      SizedBox(
        height: regEvents.isEmpty ? 200 : regEvents.length * 220.0, //weird height calculation but it works i guess
        child: regEvents.isEmpty
            ? const Center(
                child: Text(
                  "No registered events!",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              )
            : ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: regEvents.length,
                itemBuilder: (context, index) {
                  final event = regEvents[index];
                  return GestureDetector(
                    onTap: () => showEventDetails(context, event, widget.user, widget.org, isRegisteredEvent: true),
                    child: Container(
                      width: double.infinity, //full width of the container
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: generateColorFromEventName(event.name),
                        borderRadius: BorderRadius.circular(24), 
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // ClipRRect(
                            //   borderRadius: BorderRadius.all(Radius.circular(30)),
                            //   child: Image.asset(
                            //     event.imagePath, // Assuming each event has an imagePath
                            //     height: 150,
                            //     fit: BoxFit.fitWidth,
                            //   ),
                            // ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          event.name, 
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black, 
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        FittedBox(
                                          child: Row(
                                            children: <Widget>[
                                              const Icon(Icons.location_on),
                                              const SizedBox(width: 5),
                                              Text(
                                                event.city, 
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black, 
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                  flex: 1,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      event.date.toUpperCase(), 
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black, 
                                      ),
                                    )
                                  ),
                                ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    ];
  }



  List<Widget> _buildNearbyEvents() {

    if (_markers.isEmpty) { // this will check if markers are already added for nearby event
        for (Event event in mapEvents) {
          _addMarkerForEvent(event); // here we add each event as a marker
        }
      }

    return [
      const Text(
        'Nearby Events (Google Maps)',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color.fromRGBO(210, 153, 227, 1)),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _zipCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Enter Zip Code', border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              _moveMapToZipCode(_zipCodeController.text);
            },
            child: const Text('Go'),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Container(
        height: 700,
        decoration: BoxDecoration(
          color: Colors.greenAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4))],
        ),
        child: _selectedTab == 4
            ? GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                },
                initialCameraPosition: CameraPosition(target: _center, zoom: 11.0),
                markers: _markers,
                zoomControlsEnabled: true,
                myLocationEnabled: true,
              )
            : Container(), // Empty container for other tabs
      ),
    ];
  }

  }
