import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:test_drive/edit_profile.dart';
import 'package:flutter/services.dart';
import 'package:test_drive/main.dart';
import 'sign_up.dart';
import 'utils.dart';
import 'user.dart';
import 'base_url.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; 
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; 
import 'package:path_provider/path_provider.dart';
import 'qrCode_imports/platform_utils.dart';
import 'qrCode_imports/conditional_imports.dart';
import 'package:share_plus/share_plus.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.user, this.org});
  final ApiGetUser? user;
  final ApiGetOrg? org;

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Event> userEvents = [];
  List<VolunteerAvailability> userAvailabilities = [];
  Map<int, List<String>> groupedAvailabilities = {};
  bool _isLoading = true;
  bool _availabilitiesLoading = true;
  bool _isOldEventBoxChecked = false;
  String baseUrl = UrlHelper.getBaseUrl(); //get base url for all api calls here
  String? _profileImageUrl;
  String? _initials;

  static const Map<int, String> dayOfWeekNames = {
    1: "Monday",
    2: "Tuesday",
    3: "Wednesday",
    4: "Thursday",
    5: "Friday",
    6: "Saturday",
    7: "Sunday"
  };

  @override
  void initState() {
    super.initState();
    fetchUserEvents();
    if(widget.user?.userType == 1) {
      fetchUserAvailabilties();
    }
    _fetchProfilePhoto();
    _initials = "${widget.user?.firstName![0].toUpperCase()}${widget.user?.lastName![0].toUpperCase()}";
  }

  Future<void> _uploadProfilePhoto(XFile pickedFile) async {
    try {
      FormData formData;
      String userId = widget.user?.idNumber.toString() ?? 'default';

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: 'profile_picture_$userId.jpg'),
        });
        String apiUrl = '$baseUrl/api/User/uploadProfilePhoto?userIdNumber=${widget.user?.idNumber}';
        print(apiUrl);
        final response = await Dio().post(apiUrl, data: formData);
        handleResponse(response);
      } else {
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(pickedFile.path, filename: 'profile_picture_$userId.jpg'),
        });

        String apiUrl = '$baseUrl/api/User/uploadProfilePhoto?userIdNumber=${widget.user?.idNumber}';
        print(apiUrl);

        final response = await Dio().post(apiUrl, data: formData);
        handleResponse(response);
      }
    } catch (e) {
      print("Upload error: $e");
    }
  }

  Future<String?> _getQRCodeUrl(int eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/Event/GetEventQRCode?eventId=$eventId'),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      //empty or no-content response
      if (response.statusCode == 204 || response.body.isEmpty) {
        print("No QR code available for this event.");
        return null;
      }

      //response content is plain text URL
      final contentType = response.headers['content-type'];
      if (contentType != null && contentType.contains("text/plain")) {
        final qrCodeUrl = response.body.trim();
        if (qrCodeUrl.startsWith("http")) {
          return qrCodeUrl; // return the URL string
        }
      }

      print("Unexpected response format or content type.");
      return null;
    } catch (e) {
      print("Error fetching QR code: $e");
      return null;
    }
  }
  
  Future<void> _downloadQRCode(String imageUrl) async {
  try {
    if (kIsWeb) {
      downloadQRCode(imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code downloaded successfully for web')),
      );
    } else {
      await downloadQRCode(imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code downloaded successfully')),
      );
    }
  } catch (e) {
    print('Error downloading QR code: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to download QR code')),
    );
  }
}

  void removeOldEvents(bool value) {
    _isOldEventBoxChecked = value;

    if (_isOldEventBoxChecked) {
      setState(() {
        userEvents.removeWhere((event) {
        DateTime eventDate = DateFormat("M/d/yyyy").parse(event.date); // Assuming event.date is in 'M/d/yyyy' format
        DateTime currentDate = DateTime.now();
        return eventDate.isBefore(currentDate); // Remove events that are before the current date
        });
      });

    } else {
      setState(() {
        fetchUserEvents();
      });
    }
  }





  void handleResponse(Response response) {
    if (response.statusCode == 200) {
      print("Uploaded successfully");

    } else {
      print("Upload failed: ${response.statusCode} - ${response.data}");

    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await _uploadProfilePhoto(pickedFile);
    } else {
      print("No image selected.");
    }
  }

  Future<void> _fetchProfilePhoto() async {
    try {
      final response = await Dio().get('$baseUrl/api/User/GetUserProfilePhoto?userId=${widget.user?.idNumber}');

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

  Future<void> fetchUserEvents() async {
    final userId = widget.user?.idNumber;
    try {
      userEvents = await getUserEvents(userId);
    } catch (e) {
      print('Error fetching user events: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Event>> getUserEvents(int? userId) async {
    if (userId == null) return [];
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/Event/GetEventsByHost?hostId=$userId'));
      if (response.statusCode == 200) {
        return welcomeFromJson(response.body); // Ensure welcomeFromJson is correct
      } else {
        print('Failed to load user events. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user events: $e');
    }
    return [];
  }

  Future<void> fetchUserAvailabilties() async {
    final userId = widget.user?.idNumber;
    try {
      userAvailabilities = await getUserAvailabilities(userId);
      groupedAvailabilities = getGroupedAvailabilities(userAvailabilities);
    } catch (e) {
      print('Error fetching user availabilties: $e');
    } finally {
      setState(() {
        _availabilitiesLoading = false;
      });
    }
  }

  Future<List<VolunteerAvailability>> getUserAvailabilities(int? userId) async {
    if (userId == null) return [];
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/GetVolunteerAvailabilityWithUserId?id=$userId'));
      if (response.statusCode == 200) {
        return availabiltiesFromJson(response.body); // Ensure availabilitiesFromJson is correct
      } else {
        print('Failed to load user availabilities. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user availabilities: $e');
    }
    return [];
  }

  Future<List<ApiGetUser>?> getRegisteredVolunteers(int eventId) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/api/Organization/GetRegisteredVolunteersForEvent/$eventId'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body); 
      return jsonList.map((json) => ApiGetUser.fromJson(json)).toList(); 
    } else {
      print('Failed to load registered volunteers. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching registered volunteers: $e');
  }
  return null;
}

  Future<int?> getRegisteredVolunteersCount(int eventId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/Event/GetCountOfRegisteredVolunteers?eventId=$eventId'));
      if (response.statusCode == 200) {
        return int.tryParse(response.body); 
      } else {
        print('Failed to load volunteers count. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching registered volunteers count: $e');
    }
    return null;
  }

  void _copy(String volunteerDetails) {
    Clipboard.setData(ClipboardData(text: volunteerDetails));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
  }

  void _showEventDetailsDialog(int eventId) async {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text('Loading...'),
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Fetching event details...'),
            ],
          ),
        );
      },
    );

    int? volunteersCount = await getRegisteredVolunteersCount(eventId);
    List<ApiGetUser>? registeredVolunteers = await getRegisteredVolunteers(eventId);
    String volEmails = '';

    String volunteerDetails = 'Number of Registered Volunteers: ${volunteersCount ?? 'Unable to fetch'}\n\n';

    volunteerDetails += 'Registered Volunteer Info:\n\n';
  
    if (registeredVolunteers != null && registeredVolunteers.isNotEmpty) {
      for (var volunteer in registeredVolunteers) {

        volunteerDetails += '${volunteer.firstName} ${volunteer.lastName} - ${volunteer.email}\n'; 
        volEmails += '${volunteer.email}, ';
      }
      volEmails = volEmails.substring(0, volEmails.length - 2); //remove comma from last one
    } else {
      volunteerDetails += 'No registered volunteers found.'; 
    }

    Navigator.of(context).pop();
    
    showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Event Details'),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(volunteerDetails),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24.0, right:15.0), 
              child: IconButton(
                onPressed: () {
                  _copy(volEmails); 
                },
                icon: const Icon(Icons.copy),
                tooltip: 'Copy email list to clipboard',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );

  }

  Map<int, List<String>> getGroupedAvailabilities(List<VolunteerAvailability> availabilities) {
    // Step 1: Sort availabilities by dayOfWeek and startTime
    availabilities.sort((a, b) {
      int dayComparison = a.dayOfWeek.compareTo(b.dayOfWeek);
      if (dayComparison != 0) return dayComparison;
      return a.startTime.compareTo(b.startTime);
    });

    // Step 2: Filter out duplicates and group by dayOfWeek
    Map<int, List<String>> groupedAvailabilities = {};
    Set<String> seenDaysAndTimes = {};

    for (var availability in availabilities) {
      if (availability.dayOfWeek < 1 || availability.dayOfWeek > 7) {
        continue; // Skip invalid days
      }

      String timeRange = '${availability.startTime} - ${availability.endTime}';
      String uniqueKey = '${availability.dayOfWeek}-$timeRange';

      if (!seenDaysAndTimes.contains(uniqueKey)) {
        seenDaysAndTimes.add(uniqueKey);

        // Add the time range to the appropriate day in groupedAvailabilities
        if (groupedAvailabilities.containsKey(availability.dayOfWeek)) {
          groupedAvailabilities[availability.dayOfWeek]!.add(timeRange);
        } else {
          groupedAvailabilities[availability.dayOfWeek] = [timeRange];
        }
      }
    }

    return groupedAvailabilities;
  }

  void _showDeleteVolunteerAvailabilityDialog(int dayOfWeek) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Availability'),
          content: const Text('Are you sure you want to delete your first listed availability?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); 
                await deleteAvailability(dayOfWeek); 
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteAvailability(int dayOfWeek) async {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Loading..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      var id = widget.user?.idNumber;

      http.Response response = await http.delete(
        Uri.parse("$baseUrl/DeleteVolunteerAvailabilityWithIdAndDay?id=$id&day=$dayOfWeek"),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => MyHomePage(title: "LVH", user: widget.user, org: widget.org, index: 5)),
        );
      } else {
        Navigator.of(context).pop(); // Close loading dialog
        print('Failed to delete availability. Status code: ${response.statusCode}');
      }
      
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      print('Error deleting avialability: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String type = widget.user?.userType == 2 ? "Non-Profit Organization" : "Volunteer";
    print("in build, $_profileImageUrl");

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Container(
              width: MediaQuery.of(context).size.width - 40,
              height: 300,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Positioned(
                    top: 30,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.user?.firstName} ${widget.user?.lastName}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          type,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Email: ${widget.user?.email}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Phone Number: ${widget.user?.phoneNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Birthday: ${widget.user?.dob}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${widget.user?.state}, ${widget.user?.zip}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        
                      ],
                    ),
                    
                  ),
                  
                  Positioned(
                    right: 50,
                    top: 10,
                    child: CircleAvatar(
                      
                      radius: 50,
                      backgroundColor: Colors.purple,
                      backgroundImage: 
                      _profileImageUrl != null ? NetworkImage(_profileImageUrl!,) : null,
                      child: _profileImageUrl == null
                          ? Text(
                              _initials ?? '',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfile(user: widget.user!, org: widget.org), // Replace with your settings page widget
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.settings,
                      size: 32,
                      color: Colors.grey, // Set the color of the settings icon
                    ),
                  ),
                ],
              ),
            ),
            
            
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Upload Profile Picture'),
            ),


            // Availabilities Section

            if(widget.user?.userType == 1) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                child: Text(
                  "Your Availabilities",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _availabilitiesLoading
                ? const Center(child: CircularProgressIndicator())
                : userAvailabilities.isEmpty
                    ? const Center(child: Text('No availabilities found.'))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: groupedAvailabilities.length,
                        itemBuilder: (context, index) {
            
                          int dayOfWeek = groupedAvailabilities.keys.elementAt(index);
                          String? dayName = dayOfWeekNames[dayOfWeek];


                          String timeRanges = groupedAvailabilities[dayOfWeek]!.join(", ");

                          return ListTile(
                            title: Row(
                              children: [
                                Text('$dayName: $timeRanges'),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () => _showDeleteVolunteerAvailabilityDialog(dayOfWeek), 
                                  child: const Text('Delete First Availability')
                                ),
                              ]
                            )
                          );
                        },
                      ),

              const SizedBox(height: 20),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,  
                children: [
                  const Text(
                    "Your Events",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const Text("Remove past events"),
                      Checkbox(
                        value: _isOldEventBoxChecked,
                        onChanged: (bool? value) {
                          if (value != null) {
                            removeOldEvents(value);  
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _isLoading
              ? const Center(child: CircularProgressIndicator())
              : userEvents.isEmpty
                  ? const Center(child: Text('No events found.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: userEvents.length,
                      itemBuilder: (context, index) {
                        List<Event> sortedEvents = List.from(userEvents)
                        ..sort((a, b) {
                          // Use DateFormat to parse the date strings into DateTime objects
                          DateTime aDate = DateFormat("M/d/yyyy").parse(a.date);
                          DateTime bDate = DateFormat("M/d/yyyy").parse(b.date);
                          return bDate.compareTo(aDate); // Compare dates
                        });

                      final event = sortedEvents[index];
                      DateTime eventDate = DateFormat("M/d/yyyy").parse(event.date); // Parse the date for comparison
                      bool hasPassed = eventDate.isBefore(DateTime.now());

                        return Card(
                          child: ListTile(
                            title: Text(event.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${event.date}'),
                                if (hasPassed)
                                  const Text(
                                    'This event has passed',
                                    style: TextStyle(color: Colors.red),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min, // Keep trailing items compact
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                                  tooltip: 'Event QR Code',
                                  onPressed: () async {
                                    final qrImageUrl = await _getQRCodeUrl(event.id); //function to get the URL as a string

                                    if (qrImageUrl != null) {
                                      final qrImage = Image.network(qrImageUrl); //image widget to display the QR code
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Event QR Code'),
                                            content: qrImage,
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('Close'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  // lets pass the URL to the download function
                                                  await _downloadQRCode(qrImageUrl);
                                                },
                                                child: const Text('Download'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Failed to load QR Code')),
                                      );
                                    }
                                    
                                  },
                                ),
                                // Edit Event Icon
                                IconButton(
                                  icon: const Icon(Icons.event, color: Colors.blue),
                                  tooltip: 'View Event',
                                  onPressed: () async {
                                    showEventDetails(context, event, widget.user, widget.org, isRegisteredEvent: false);
                                    
                                    setState(() {
                                      
                                    });
                                  },
                                ),
                                // View Details Button
                                TextButton(
                                  onPressed: () => _showEventDetailsDialog(event.id),
                                  child: const Text('View Registration Stats'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min, // Ensures the row only takes as much space as needed
                mainAxisAlignment: MainAxisAlignment.center, // Centers the buttons horizontally
                children: [
                  IconButton(
                    tooltip: "Share LVH",
                    icon: const Icon(Icons.share),
                    onPressed: () async {
                      final result = await Share.shareWithResult(
                        'Interested in volunteering events in your area? Check out Local Volunteering Hub: https://localvolunteeringhub-3995a.web.app/',
                      );
                      print(result.status);
                    },
                    iconSize: 45,
                  ),
                  const SizedBox(width: 20), // Space between the buttons
                  IconButton(
                    tooltip: "Log Out",
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () async {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    iconSize: 45,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}