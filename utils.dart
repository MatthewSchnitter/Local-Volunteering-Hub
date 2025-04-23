import 'dart:convert';
//import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_drive/add_event_page.dart';
import 'package:test_drive/organizer_profile.dart';
import 'user.dart'; 
import 'base_url.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:auto_size_text/auto_size_text.dart';


class EventDetails extends StatefulWidget{
  final Event event;
  final ApiGetUser? user;
  final ApiGetOrg? org;
  final bool isRegisteredEvent;
  final VoidCallback? onRefreshLikesAndRegs;

  const EventDetails({super.key, required this.event, this.user, this.org, required this.isRegisteredEvent, this.onRefreshLikesAndRegs});

  @override
  _EventDetailsState createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  bool _isSaved = false;
  bool _isLoading = true;
  bool _isOrg = true;
  bool _isRegistered = false;
  String? eventHostName;
  String? registerButtonText;
  String? registerText;
  ApiGetOrg? _eventHostOrg;
  ApiGetUser? _eventHostUser;
  int numRegVols = 0;
  String? _profileImageUrl;
  String baseUrl = UrlHelper.getBaseUrl(); //get base url for all api calls here
  List<Interest> _eventInterests = [];

  late Event _initialEvent; 
  late Event _currentEvent;

  List<String?> eventPhotos = [];

  @override
  void initState() {
    super.initState();
    _initialEvent = widget.event;  
    _currentEvent = _initialEvent;
    _initializePage();

  }

  void _initializePage() {
    _fetchOrganizationDetails();
    _checkIfSaved();
    _checkIfRegistered();
    
    _fetchProfilePhoto();
    _fetchPhotos();
    _fetchRegCount();
    _fetchEventInterests();
  }

  Future<void> _fetchPhotos() async {
    eventPhotos = await getEventPhotos(widget.event.id); // Replace 95 with your event ID
    setState(() {});
  }

  Future<void> _fetchUpdatedEvent() async {
    var updatedEvent = await fetchEventById(_currentEvent.id); // Replace with your API call
    print("new event name: ${updatedEvent!.name}");
    setState(() {
      _currentEvent = updatedEvent; // Update the event with the new data
      _initializePage();
    });
  }

  Future<List<String>> getEventPhotos(int eventId) async {
    final String apiUrl = 'https://localhost:7091/api/Event/GetEventImages?eventId=$eventId';
    
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        List<String> photoUrls = jsonData.map((photo) => photo['url'].toString()).toList();

        return photoUrls;
      } else {
        print('Failed to fetch photos. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching photos: $e');
      return [];
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(), // Close dialog on tap
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.broken_image,
                  size: 120,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Event?> fetchEventById(int eventId) async {
    var url = Uri.parse("$baseUrl/api/Event/GetEventsWithIds");
    try {
      var body = jsonEncode([eventId]);

      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "accept": "text/plain",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          print("event found");
          return Event.fromJson(data[0]); // Parse and return the event
        } else {
          print("No event found for ID: $eventId");
          return null;
        }
      } else {
        print("Failed to fetch event: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching event: $e");
      return null;
    }
  }


  Future<void> _fetchEventInterests() async {
    final eventId = _currentEvent.id;
    final url = Uri.parse("$baseUrl/api/Event/GetInterestsForEvent?eventId=$eventId");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final interestsJson = jsonDecode(response.body) as List;
        print("interests returned: $interestsJson");
        setState(() {
          _eventInterests = interestsJson
              .map((json) => Interest.fromJson(json))
              .toList();
        });
      } else {
        print("Failed to load interests: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching interests: $e");
    }
  }

  Future<void> _scanQRCode() async {
    //if (baseUrl == 'https://localhost:7091')
  if (kIsWeb) {
    // This is either web or default case (e.g., iOS running locally)
    final TextEditingController passphraseController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Passphrase"),
          content: TextFormField(
            controller: passphraseController,
            decoration: const InputDecoration(
              labelText: "Passphrase",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final String passphrase = passphraseController.text.trim();

                if (passphrase.isEmpty) {
                  // Show an error if the passphrase is empty
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Error"),
                        content: const Text("Passphrase cannot be empty."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  Navigator.of(context).pop(); // Close the input dialog
                  await _markAttendance(passphrase); // Pass the entered passphrase
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  } else if (Platform.isAndroid) {
    //else if (baseUrl == 'https://10.0.2.2:7091')
    // this is Android
    try {
      String qrCode = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', // Line color
        'Cancel',  // Cancel button text
        true,      // Flash icon
        ScanMode.QR // QR code mode
      );

      if (qrCode != '-1') {
        print('Scanned QR Code: $qrCode'); // Debug print
        await _markAttendance(qrCode); // Mark attendance
      }
    } catch (e) {
      print('Error scanning QR code: $e');
    }
  } else {
    // Fallback for other platforms (e.g., iOS or unknown platforms)
    print("Platform not supported for this feature.");
  }
}

/*
  Future<void> _scanQRCode() async {
    try {
      String qrCode = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', // the color of the line or frame around the scanning area
        'Cancel',  // text for cancel button
        true,      // show flash icon
        ScanMode.QR // setting scan mode to QR
      );

      if (qrCode != '-1') {
        print('Scanned QR Code: $qrCode'); //printing out the scanned data
        _markAttendance(qrCode);  //mark attendance
      }
    } catch (e) {
      print('Error scanning QR code: $e');
    }
  }
*/
  Future<void> _markAttendance(String qrCodeData) async {
    final RegExp regex = RegExp(r'\d+'); 
    final match = regex.firstMatch(qrCodeData);
    String? passphrase = match?.group(0); // get the passphrase ex; "876491"

    // validate the passphrase
    if (passphrase == null || passphrase.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: const Text("Passphrase is missing or invalid."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return; 
    }

    int userId = widget.user?.idNumber ?? -1; 
    int eventId = widget.event.id;

    final TextEditingController qrCodeController = TextEditingController(text: passphrase);
    final TextEditingController userIdController = TextEditingController(text: userId.toString());
    final TextEditingController eventIdController = TextEditingController(text: eventId.toString());

    //dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Check-In Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: qrCodeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Check-In Code",
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: userIdController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "User ID",
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: eventIdController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Event ID",
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); 
                await _verifyQrCheckIn(eventId, userId, passphrase);
              },
              child: const Text("Verify"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifyQrCheckIn(int eventId, int userId, String passphrase) async {
    final url = Uri.parse('$baseUrl/api/Event/VerifiedQrCheckIn?eventId=$eventId&userId=$userId&passphrase=$passphrase');


    //data being sent
    //print("API Request Debug:");
    //print("Event ID: $eventId");
    //print("User ID: $userId");
    //print("Passphrase: $passphrase");

    // lets validate fields before making the API call
    if (passphrase.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Passphrase is missing or invalid."),
                const SizedBox(height: 8),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return; 
    }

    try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "text/plain",
      },
      body: jsonEncode({
        'eventId': eventId,
        'userId': userId,
        'passphrase': passphrase,
      }),
    );

    if (response.statusCode == 200) {
      // Success: Parse the JSON response
      final responseData = jsonDecode(response.body);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Check-In Successful"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              /*
              children: [
                Text("ID: ${responseData['id']}"),
                Text("Org ID: ${responseData['orgId']}"),
                Text("Volunteer ID: ${responseData['volunteerId']}"),
                Text("Event ID: ${responseData['eventId']}"),
                Text("Volunteer Rating: ${responseData['volunteerRating']}"),
                Text("Volunteer Attended: ${responseData['volunteerAttended']}"),
              ],*/
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } else if (response.statusCode == 400) {
      // Bad Request: Parse the error response
      final errorData = jsonDecode(response.body);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Check-In Failed"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Make you are scanning the right QR Code"),
          
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } else {
      // other non-success responses
      final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text(
                "Incorrect Passphrase"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  } catch (e) {
    //  exceptions
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text("An error occurred: $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }


  final Map<InterestCategory, IconData> interestIconMap = {
    InterestCategory.environmentalConservation: Icons.eco,         // Environmental Conservation
    InterestCategory.communityService: Icons.volunteer_activism,  // Community Service
    InterestCategory.educationTutoring: Icons.school,             // Education & Tutoring
    InterestCategory.healthWellness: Icons.favorite,              // Health & Wellness
    InterestCategory.youthDevelopment: Icons.child_care,           // Youth Development
    InterestCategory.artsCulture: Icons.brush,                     // Arts & Culture
    InterestCategory.animalWelfare: Icons.pets,
    InterestCategory.disasterRelief: Icons.tornado,                 // Disaster Relief
    InterestCategory.seniorServices: Icons.elderly,                 // Senior Services
    InterestCategory.advocacySocialJustice: Icons.gavel,           // Advocacy & Social Justice
    InterestCategory.sportsRecreation: Icons.sports,               // Sports & Recreation
  };

  

  Widget _buildInterestIcons() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: _eventInterests
          .where((interest) => interest.interests != InterestCategory.none) // Exclude "None" category
          .map((interest) {
            final icon = interestIconMap[interest.interests] ?? Icons.help; 
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: Colors.blueAccent), 
                const SizedBox(height: 8),
                Text(
                  _capitalizeInterestName(interest.interests.toString().split('.').last),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            );
          }).toList(),
    );
  }


  String _capitalizeInterestName(String name) {
    const interestMappings = {
      'environmentalConservation': 'Environmental Conservation',
      'communityService': 'Community Service',
      'educationTutoring': 'Education Tutoring',
      'healthWellness': 'Health and Wellness',
      'youthDevelopment': 'Youth Development',
      'artsCulture': 'Arts and Culture',
      'disasterRelief': 'Disaster Relief',
      'seniorServices': 'Senior Services',
      'advocacySocialJustice': 'Advocacy and Social Justice',
      'sportsRecreation': 'Sports and Recreation',
    };
    return interestMappings[name] ?? name
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
          return '${match.group(1)} ${match.group(2)}'; 
        })
        .replaceAll('_', ' ')  
        .split(' ')          
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()) 
        .join(' ');            
  }


  Future<void> _fetchRegCount() async{
    numRegVols = await _getCountOfRegisteredVols();
  }

  Future<int>_getCountOfRegisteredVols() async{
    final response = await http.get(Uri.parse("$baseUrl/api/Event/GetCountOfRegisteredVolunteers?eventId=${_currentEvent.id}"));

    final c = jsonDecode(response.body);
    return c;
  }

  Future<void> _checkIfRegistered() async {
    final r = await http.get(Uri.parse("$baseUrl/api/Volunteer/IsVolunteerRegisteredForAnEvent/${widget.user?.idNumber}/${_currentEvent.id}"));
    bool rResponse = jsonDecode(r.body);
    print("_isRegistered=$rResponse");
    _isRegistered = rResponse;
  }

  //check if the event is already saved
  Future<void> _checkIfSaved() async {
    final response = await http.get(Uri.parse("$baseUrl/api/Event/GetUsersFavoritedEvents?userId=${widget.user?.idNumber}"));
    final evt = welcomeFromJson(response.body); 
    for(Event ev in evt){
      if(ev.id == _currentEvent.id){
        setState(() {
          _isSaved = true;
        });
      }
    }
  }

  //fetch organization details
  Future<void> _fetchOrganizationDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/Organization/GetOrganizationById/${_currentEvent.host}'),
      );

      if (response.statusCode == 200) {
        //print(response.body);
        setState(() {
          _eventHostOrg = apiGetSingleOrgFromJson(response.body);
          _isLoading = false;
        });
        print(_eventHostOrg!.userId);
      } else { //not an org, just a user
        final response2 = await http.get(
          Uri.parse('$baseUrl/api/Volunteer/GetVolunteersWithId/${_currentEvent.host}'),
        );
        if(response2.statusCode == 200){
          setState(() {
            _eventHostUser = apiGetSingleUserFromJson(response2.body);
            _isOrg = false;
            _isLoading = false;
        });
        print(_eventHostUser!.idNumber);
        }
        
      }
    } catch (error) {
      print('Error occurred while fetching organization details: $error');
    }
  }

  Future<void> _fetchProfilePhoto() async {
    try {
      final response = await Dio().get('$baseUrl/api/User/GetUserProfilePhoto?userId=${widget.event.host}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Check if the response is a single profile photo object
        if (data is Map<String, dynamic>) {
          if (data.containsKey('url')) {
            setState(() {
              _profileImageUrl = data['url']; // Extract the URL directly
            });
            print("Profile image URL: $_profileImageUrl");
          } else {
            print("Profile photo URL not found in response");
          }
        } else {
          print("Unexpected response format: ${response.data}");
        }
      } else {
        print("Failed to fetch profile photo: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching profile photo: $e");
    }
  }

  void _displayRegisterYesDialog() {
    String regDialog;
    
    if (_currentEvent.eventLink == null || _currentEvent.eventLink == '') {
      regDialog = 'You are all set!';
    } else {
      regDialog = 'Make sure to register for this event through the organizers page here: ';
    }
    
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Success!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(regDialog),
            if (_currentEvent.eventLink != null && _currentEvent.eventLink!.isNotEmpty)
              GestureDetector(
                onTap: () async {
                  // Check if the URL can be launched
                  final Uri url = Uri.parse(_currentEvent.eventLink!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
                child: Text(
                  _currentEvent.eventLink!,
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

   void _displayRegisterNoDialog(){
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Successfully Unregistered'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  //handle registering for event
  Future<void> _handleRegister() async {
    print("handling register button press, isReg = $_isRegistered");
    try {
      if (_isRegistered == true) {
        final response = await http.put(
           Uri.parse('$baseUrl/api/Volunteer/UnRegisterVolunteerFromEvent?userId=${widget.user?.idNumber}&eventId=${_currentEvent.id}'),
         );

        if (response.statusCode == 200) {
          setState(() {
            _isRegistered = false;
          });
          _displayRegisterNoDialog();
          homePageKey.currentState?.refereshLikesAndRegs();
        } else {
          print('Failed to remove reg. Status code: ${response.statusCode}');
        }
      } else {
        print("${_currentEvent.id}");
        final response2 = await http.put(
          Uri.parse('$baseUrl/api/Volunteer/AddVolunteerRegisteredEvent?userId=${widget.user?.idNumber}&eventId=${_currentEvent.id}'),
        );
        print("response2 = ${response2.body}");

        if (response2.statusCode == 200) {
          print("successfully registered");
          setState(() {
            _isRegistered = true;
          });
          _displayRegisterYesDialog();
          homePageKey.currentState?.refereshLikesAndRegs();
        } else {
          print('Failed to add reg Status code: ${response2.statusCode}');
        }
      }
    } catch (error) {
      print('Error occurred while updating favorite status: $error');
    }
  }

  //handle like/unlike event
  Future<void> _handleLike() async {

    print("in handleLike");
    try {
      if (_isSaved == true) {
        print("is saved is true");
        final response = await http.put(
          Uri.parse('$baseUrl/api/Volunteer/UnfavoriteEventForVolunteer?userId=${widget.user?.idNumber}&eventId=${_currentEvent.id}'),
        );

        if (response.statusCode == 200) {
          setState(() {
            print("succesfully unliked");
            _isSaved = false;
          });
          homePageKey.currentState?.refereshLikesAndRegs();
        } else {
          print('Failed to remove event from favorites. Status code: ${response.statusCode}');
        }
      } else {
        print("in _handleLike, _isSaved=$_isSaved");
        final response = await http.put(
          Uri.parse('$baseUrl/api/Volunteer/AddVolunteerFavortiedEvent?userId=${widget.user?.idNumber}&eventId=${_currentEvent.id}'),
        );

        if (response.statusCode == 200) {
          print("successfully liked");
          setState(() {
            _isSaved = true;
          });
          homePageKey.currentState?.refereshLikesAndRegs();
        } else {
          print('Failed to add event to favorites. Status code: ${response.statusCode}');
        }
      }
    } catch (error) {
      print('Error occurred while updating favorite status: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime parsedDate = DateFormat('M/d/yyyy').parse(_currentEvent.date);
    return SafeArea(
    child: Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100), 
        child: AppBar(
          automaticallyImplyLeading: false, 
          backgroundColor: const Color.fromARGB(255, 238, 168, 251), 
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 40.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context); 
                  },
                ),
                const SizedBox(width: 16), 
                const Text(
                  'Event Details',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
        body: DraggableScrollableSheet(
          initialChildSize: 1.0,  
          minChildSize: 1.0,      
          maxChildSize: 1.0,      
        
          builder: (BuildContext context, ScrollController scrollController) {
            if(_isOrg){
              eventHostName = "${_eventHostOrg?.orgName}";
            }
            else{
              eventHostName = "${_eventHostUser?.userName}";
            }
            if(_isLoading){
              return const Center(child: CircularProgressIndicator());
            }
            if(_isRegistered){
              registerButtonText = "Unregister from event";
              registerText = "Congratulations! You are regsitered for this event!";
            }
            else{
              registerButtonText = "Let the organizer know you plan on attending!";
              registerText = "Plan on Attending? Click here!";
            }
            return Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    ListView(
                      controller: scrollController,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: AutoSizeText(
                                _currentEvent.name,
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 3,
                                minFontSize: 24, 
                                wrapWords: true, 
                              ),
                            ),
                            
                            if (_currentEvent.host == widget.user?.idNumber) ...[
                              
                              IconButton(
                                tooltip: "Edit Event",
                                icon: const Icon(Icons.edit_outlined),
                                iconSize: 32,
                                onPressed: () async {
                                  print("interests: $_eventInterests");
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddEventPage(
                                        selectedDay: parsedDate.toIso8601String(),
                                        user: widget.user,
                                        isEditing: true,
                                        event: _currentEvent,
                                        interestList: _eventInterests,
                                      ),
                                    ),
                                  ).then((result){
                                    if (result != null && result) {
                                      print("event change detected");
                                      setState(() {
                                        _fetchUpdatedEvent();
                                        _fetchEventInterests();
                                      });
                                    }
                                  });
                                  if (result == true) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    _initializePage();
                                  }
                                },
                              ),
                            ],
                            
                            if (widget.user?.userType == 1) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: IconButton(
                                      icon: Icon(
                                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                                        color: _isSaved ? Colors.purple : Colors.grey,
                                        size: 36,
                                      ),
                                      tooltip: 'Bookmark Event',
                                      onPressed: _handleLike,
                                      iconSize: 36,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      eventHostName!,
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    if (_isOrg) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.verified,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                    ],
                                  ],
                                ),
                                if (_isOrg)
                                  const Text(
                                    'This is a verified Non-Profit',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                            GestureDetector(
                              onTap: _eventHostOrg == null
                                  ? null // Disable tap for volunteers
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => OrganizerPage(
                                            organization: _eventHostOrg!,
                                            user: widget.user!,
                                            profileImageUrl: _profileImageUrl,
                                            initials: eventHostName![0],
                                          ),
                                        ),
                                      );
                                    },
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.purple, // Set your desired background color
                                    backgroundImage: _profileImageUrl != null
                                        ? NetworkImage(
                                            _profileImageUrl!,
                                          )
                                        : null,
                                    child: _profileImageUrl == null
                                        ? Text(
                                            eventHostName?[0] ?? '',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 4), // Space between the icon and text
                                  Text(
                                    _eventHostOrg == null ? 'Volunteer' : 'View Profile',
                                    style: const TextStyle(
                                      fontSize: 12, // Smaller font for the label
                                      color: Color.fromARGB(255, 255, 255, 255), // Set the text color to match the theme
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]
                        ),
                        const SizedBox(height: 24),
                       if (eventPhotos.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Event Photos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: eventPhotos.map((photoUrl) {
                                    return GestureDetector(
                                      onTap: () => _showImageDialog(context, photoUrl!),
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            photoUrl!,
                                            width: 200,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                          (loadingProgress.expectedTotalBytes ?? 1)
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              Icons.broken_image,
                                              size: 120,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
 
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // Aligns the icon and text at the top
                          children: [
                            Icon(
                              Icons.description, // You can choose any appropriate icon
                              color: Colors.grey[500],
                              size: 24, // Adjust size as needed
                            ),
                            const SizedBox(width: 8), // Add some space between the icon and text
                            Expanded( // Wraps the text to avoid overflow
                              child: Text(
                                _currentEvent.description,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // Aligns the icon and text at the top
                          children: [
                            Icon(
                              Icons.date_range, // You can choose any appropriate icon
                              color: Colors.grey[500],
                              size: 24, // Adjust size as needed
                            ),
                            const SizedBox(width: 8), // Add some space between the icon and text
                            Expanded( // Wraps the text to avoid overflow
                              child: Text(
                                _currentEvent.date,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on, // Location icon
                              color: Colors.grey[500],
                              size: 24,
                            ),
                            const SizedBox(width: 8), // Space between icon and text
                            Expanded(
                              child: Text(
                                '${_currentEvent.street}, ${_currentEvent.city}, ${_currentEvent.state} ${_currentEvent.zip}, ${_currentEvent.countryCode}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.access_time, // Clock icon for time
                              color: Colors.grey[500],
                              size: 24,
                            ),
                            const SizedBox(width: 8), // Space between icon and text
                            Expanded(
                              child: Text(
                                '${_currentEvent.startTime} - ${_currentEvent.endTime}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (_currentEvent.eventLink != '') ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Link to sign up page: ',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey, // You can adjust the color for the non-clickable part
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final Uri url = Uri.parse(_currentEvent.eventLink!);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                print("Could not open the link: $url");
                              }
                            },
                            child: Text(
                              _currentEvent.eventLink!,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.blue, // Make the link text blue
                                decoration: TextDecoration.underline, // Make the link underlined
                              ),
                            ),
                          ),
                        ],
                      const SizedBox(height: 32),
                      if (_eventInterests.where((interest) => interest.interests != InterestCategory.none).isNotEmpty) ...[
                        const Text(
                          'Event Categories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInterestIcons(),
                      ],

                        
                        if (widget.user?.userType == 1) ...[
                          if(_currentEvent.openSlots > numRegVols) ...[
                            const SizedBox(height: 32),
                            Text(
                              registerText!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 16), 
                            ElevatedButton(
                              onPressed: _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[200],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                registerButtonText!,
                                style: 
                                  const TextStyle(fontSize: 16),
                                
                              ),
                            ),

                            // New button for scanning the QR code
                            if (widget.isRegisteredEvent) ...[
                              const SizedBox(height: 16), // Add spacing before the button
                              ElevatedButton(
                                onPressed: _scanQRCode, // Function to initiate QR scan
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "Check-In",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ]
                          else ...[
                            const SizedBox(height: 32),
                            const Text(
                              'Event full',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red, // Optional: You can use red to indicate an error
                              ),
                            ),

                            const SizedBox(height: 16), // Add space before the button
                            // Grayed out button when event is full
                            ElevatedButton(
                              onPressed: null, // Disable button
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey, // Gray background color
                                foregroundColor: Colors.white, // Button text color
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Register',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ]
                        ],
                      ],
                    ),
                    
                    
                    //if current user is host, they can edit / delete event
                    
                  ]
                ),
              )
            );
          },
        )
      )
    );
  }
}

//method to show the EventDetails modal
void showEventDetails(BuildContext context, Event event, ApiGetUser? user, ApiGetOrg? org, {required bool isRegisteredEvent}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return EventDetails(event: event, user: user, org: org, isRegisteredEvent: isRegisteredEvent);
    },
  );
}