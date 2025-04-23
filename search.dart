import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'utils.dart';
import 'user.dart';
import 'base_url.dart';
import 'package:http/http.dart' as http;


class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.user, this.org});
  final ApiGetUser? user;
  final ApiGetOrg? org;

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Event> events = [];
  List<Event> filteredEvents = [];
  final controller = TextEditingController();
  String baseUrl = UrlHelper.getBaseUrl(); //get base url for all api calls here
  bool _isFilterApplied = false;

  bool _filterByAvailability = false;
  List<VolunteerAvailability> availabilities = [];

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
    InterestCategory.sportsRecreation: Icons.sports_basketball,               // Sports & Recreation
  };

  static const Map<InterestCategory, String> interestCategoryNames = {
    InterestCategory.none: 'None', // Added "None"
    InterestCategory.environmentalConservation: 'Environmental Conservation',
    InterestCategory.communityService: 'Community Service',
    InterestCategory.educationTutoring: 'Education & Tutoring',
    InterestCategory.healthWellness: 'Health & Wellness',
    InterestCategory.youthDevelopment: 'Youth Development',
    InterestCategory.artsCulture: 'Arts & Culture',
    InterestCategory.animalWelfare: 'Animal Welfare', 
    InterestCategory.disasterRelief: 'Disaster Relief',
    InterestCategory.seniorServices: 'Senior Services',
    InterestCategory.advocacySocialJustice: 'Advocacy & Social Justice',
    InterestCategory.sportsRecreation: 'Sports & Recreation',
  };

  final List<InterestCategory> _selectedInterestIds = [];

  @override
  void initState() {
    super.initState();
    if(widget.user?.userType == 1) {
      fetchUserAvailabilities(widget.user?.idNumber);
    }
    fetchEvents();
  }

  Future<void> fetchUserAvailabilities(int? userId) async {
    if (userId == null) availabilities = [];
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/GetVolunteerAvailabilityWithUserId?id=$userId'));
      if (response.statusCode == 200) {
        availabilities = availabiltiesFromJson(response.body); // Ensure availabilitiesFromJson is correct
      } else {
        print('Failed to load user availabilities. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user availabilities: $e');
    }
  }

  bool isEventWithinAvailability(Event event, List<VolunteerAvailability> availabilities) {
    final eventStartTime = parseTime(event.startTime);
    final eventEndTime = parseTime(event.endTime);
    final eventDay = parseEventDay(event.date);

    return availabilities.any((availability) {
      final availabilityStartTime = parseTime(availability.startTime);
      final availabilityEndTime = parseTime(availability.endTime);
      return eventDay == availability.dayOfWeek &&
        (eventStartTime.isAfter(availabilityStartTime) || eventStartTime.isAtSameMomentAs(availabilityStartTime)) &&
        (eventEndTime.isBefore(availabilityEndTime) || eventEndTime.isAtSameMomentAs(availabilityEndTime));
    });
  }

  DateTime parseTime(String time) {
    final cleanedTime = time.replaceAll(RegExp(r'\s+'), ' ').trim();
    final format = DateFormat("hh:mm aaa");
    return format.parse(cleanedTime);
  }

  int parseEventDay(String eventDate) {
    final date = parseCustomDate(eventDate);
    return date.weekday;
  }

  DateTime parseCustomDate(String date) {
    try {
      final parts = date.trim().split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        if (month < 1 || month > 12 || day < 1 || day > 31) {
          throw const FormatException("Invalid month or day value");
        }

        return DateTime(year, month, day);
      } else {
        throw const FormatException("Invalid date format");
      }
    } catch (e) {
      print("Error parsing date: $e");
      return DateTime(1900); 
    }
  }

  Future<void> fetchEvents() async {
    final url = Uri.parse('$baseUrl/api/Event/GetEvents');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<Event> eventsList = data.map((json) => Event.fromJson(json)).toList();
        final today = DateTime.now();
        final filteredEventsList = eventsList
          .where((event) { 
            final eventDate = parseCustomDate(event.date);
            final isFutureEvent = eventDate.isAfter(today) || eventDate.isAtSameMomentAs(today);
            if(widget.user?.userType == 1) {
              final passesAvailabilityFilter = !_filterByAvailability ||
                isEventWithinAvailability(event, availabilities);
              return isFutureEvent && passesAvailabilityFilter;
            } 
            else {
              return isFutureEvent;
            }
          })
          .toList()
        ..sort((a, b) => parseCustomDate(a.date).compareTo(parseCustomDate(b.date)));
        if (mounted) {
          setState(() {
            events = eventsList; 
            filteredEvents = filteredEventsList; 
          });
        }
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  void _showInterestFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Interests"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Interests:'),
                    ...InterestCategory.values
                        .where((category) => category != InterestCategory.none) // Exclude 'none'
                        .map((category) {
                      return CheckboxListTile(
                        title: Text(
                            interestCategoryNames[category] ?? 'Unknown Interest'),
                        value: _selectedInterestIds.contains(category),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedInterestIds.add(category);
                            } else {
                              _selectedInterestIds.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Close"),
            ),
            TextButton(
              onPressed: () {
                filterEvents(_selectedInterestIds);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  Future<void> filterEvents(List<InterestCategory> intIds) async {

    final Map<InterestCategory, int> interestCategoryMap = {
      InterestCategory.none: 1,
      InterestCategory.environmentalConservation: 2,
      InterestCategory.communityService: 3,
      InterestCategory.educationTutoring: 4,
      InterestCategory.healthWellness: 5,
      InterestCategory.youthDevelopment: 6,
      InterestCategory.artsCulture: 7,
      InterestCategory.animalWelfare: 8,
      InterestCategory.disasterRelief: 9,
      InterestCategory.seniorServices: 10,
      InterestCategory.advocacySocialJustice: 11,
      InterestCategory.sportsRecreation: 12,
    };
    

    final List<int> interestIds = intIds
      .where((category) => interestCategoryMap.containsKey(category)) 
      .map((category) => interestCategoryMap[category]!)
      .toList();

    try {
      String apiUrl = '$baseUrl/api/Event/GetEventsWithInterests';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'text/plain',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(interestIds),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final List<Event> events = responseData.map((eventJson) {
          return Event.fromJson(eventJson);
        }).toList();

        final filteredEventsList = events
          .where((event) { 
            final eventDate = parseCustomDate(event.date);
            final isFutureEvent = eventDate.isAfter(DateTime.now()) || eventDate.isAtSameMomentAs(DateTime.now());
            if(widget.user?.userType == 1) {
              final passesAvailabilityFilter = !_filterByAvailability ||
                isEventWithinAvailability(event, availabilities);
              return isFutureEvent && passesAvailabilityFilter;
            } 
            else {
              return isFutureEvent;
            }
          })
          .toList()
        ..sort((a, b) => parseCustomDate(a.date).compareTo(parseCustomDate(b.date)));

        setState(() {
          filteredEvents = filteredEventsList;
        });
        _isFilterApplied = true;
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      print('Failed to fetch filtered events: $error');
    }
  }


  void searchEvent(String query) {
    if (query.isEmpty) {
      setState(() {
        fetchEvents();
      });
    } else {
      final suggestions = filteredEvents.where((ev) {
        final evTitle = ev.name.toLowerCase();
        final input = query.toLowerCase();
        return evTitle.contains(input);
      }).toList();

      setState(() => filteredEvents = suggestions);
    }
  }


  @override
  Widget build(BuildContext context) => Scaffold(

    body: Column(
      
      children: <Widget>[
        Container(
          margin: const EdgeInsets.all(16),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Event Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.purple)
              )
            ),
            onChanged: searchEvent,
          ),
        ),
        Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Align to the left
          children: [
            // Filter by Interests Button
            ElevatedButton.icon(
              icon: const Icon(Icons.filter_list),
              label: const Text(
                "Change Filters",
                style: TextStyle(color: Colors.white, fontSize: 17), // White button text
              ),
              onPressed: () => _showInterestFilterDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 61, 61, 61), // Customize button color if needed
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(width: 8), // Space between the button and checkbox
            // Checkbox to toggle filter application
            Checkbox(
              value: _isFilterApplied, // Whether the filter is applied or not
              onChanged: (bool? value) {
                setState(() {
                  _isFilterApplied = value ?? false;
                });
                // Apply the filter if checked
                if (_isFilterApplied) {
                  filterEvents(_selectedInterestIds);
                } else {
                  setState(() {
                    fetchEvents();
                  });
                  searchEvent(controller.text); // Reset search without filter
                }
              },
            ),
            if(widget.user?.userType == 1 && availabilities.isNotEmpty) ...[
              const SizedBox(width: 30),
              const Text("Show events based on set availabilities"),
              Switch(
                value: _filterByAvailability,
                onChanged: (bool value) {
                  if(mounted) {
                  setState(() {
                    _filterByAvailability = value;
                  });
                  }
                  fetchEvents();
                },
              ),
            ]
          ],
        ),
      ),
      // Display Filters and Interest Icons
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
              "Filters: ", 
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            _selectedInterestIds.isEmpty
            ? const Text(
                "none",
                style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 255, 255, 255)),
              )
            : Wrap(
              spacing: 8.0, 
              children: _selectedInterestIds
                  .where((category) => interestIconMap.containsKey(category))
                  .map((category) {
                return Tooltip(
                  message: interestCategoryNames[category], 
                  child: Icon(
                    interestIconMap[category], 
                    size: 24,
                    color: Color.fromARGB(255, 243, 133, 213),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      SizedBox(height: 16),
        Expanded(
            child: ListView.builder(
              itemCount: filteredEvents.length, 
              itemBuilder: (context, index) {
                final ev = filteredEvents[index];
                return Card(
                  elevation: 3, 
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),  
                  ),
                  child: ListTile(
                    title: Text(
                      ev.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4), 
                        Text(
                          'Date: ${ev.date}', 
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios), 
                    onTap: () => showEventDetails(context, ev, widget.user, widget.org, isRegisteredEvent: false), 
                  ),
                );
              },
            ),
          ),
      ],)
  );

}
