import 'package:flutter/material.dart';
import 'user.dart';
import 'home_page.dart';
import 'dart:convert';
import 'base_url.dart';
import 'package:http/http.dart' as http;


class NotificationsPage extends StatefulWidget  {
  final ApiGetUser? user; 
  
  const NotificationsPage({super.key, this.user});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<String> notifications = [];
  bool isLoading = true;
  String baseUrl = UrlHelper.getBaseUrl(); //get base url for all api calls here

  @override
  void initState() {
    super.initState();
    fetchEventsAndNotify();
  }

 Future<void> postNotification({
  required int idNotification,
  required int userId,
  required int eventId,
  required int read,
  required String eName,
  required String message,
}) async {


  print(userId);
  print(eventId);
  print(read);
  print(message);

  try {
    // send the request with a JSON body
    final url = '$baseUrl/CreateNotification?idNotifications=0&UserId=$userId&EventId=$eventId&Read=$read&EventName=$eName%20Name&Message=$message';

    final response = await http.post(
      Uri.parse(url), 
      headers: {'Content-Type': 'application/json'}, 
      
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('Notification created successfully!');
    } else {
      print('Failed to create notification. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (e) {
    print('Error creating notification: $e'); // Log any exceptions
  }
}





  Future<void> fetchEventsAndNotify() async {
  final userId = widget.user?.idNumber;
  if (userId == null) {
    print('User ID is null. Cannot fetch events.');
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    final response = await http.get(Uri.parse('$baseUrl/api/Volunteer/GetVolunteerRegisteredEvents/$userId'));

    if (response.statusCode == 200) {
      final List<dynamic> events = jsonDecode(response.body);
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      final tomorrowEvents = events.where((event) {
        final eventDate = parseCustomDate(event['date']);
        return _isSameDay(eventDate, tomorrow);
      }).toList();

      // post notifications for tomorrow's events
      for (var event in tomorrowEvents) {
        final message = 'Reminder: You have "${event['name']}" happening tomorrow!';
        await postNotification(
          idNotification: 0,
          userId: userId,
          eventId: event['id'],
          read: 0,
          eName: event['name'],
          message: message,
        );
      }

      // update the notifications list
      setState(() {
        notifications = tomorrowEvents.map((event) => event['name'] as String).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications sent for tomorrow\'s events!'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      print('Failed to fetch events. Status: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching events: $e');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}





  Future<void> postUpdateNotification(String eventName, int eventId) async {
    final userId = widget.user?.idNumber;
    if (userId == null) return;

    final url = Uri.parse('$baseUrl/api/Notifications/CreateNotification');
    print('Posting update notification to: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idNotifications': 0,
          'UserId': userId,
          'EventId': eventId,
          'Read': 0,
          'EventName': eventName,
          'Message': 'The event "$eventName" has been updated!',
        }),
      );

      if (response.statusCode == 200) {
        print('Update notification created successfully for "$eventName".');
      } else {
        print('Failed to create update notification. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error creating update notification: $e');
    }
  }


/*
   // Fetch events and filter those happening tomorrow
  Future<void> fetchEventsAndNotify() async {
    final userId = widget.user?.idNumber;
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/Event/GetEventsByHost?hostId=$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> events = jsonDecode(response.body);
        final tomorrow = DateTime.now().add(const Duration(days: 1));

        // Filter events happening tomorrow
        final tomorrowEvents = events.where((event) {
          final eventDate = parseCustomDate(event['date']); //  i will assume 'date' is in ISO format
          return _isSameDay(eventDate, tomorrow);
        }).toList();

        // If there are events tomorrow, update the notifications list
        if (tomorrowEvents.isNotEmpty) {
          setState(() {
            notifications = tomorrowEvents.map((e) => e['name'] as String).toList();
          });

          // Show a snackbar as a quick notification- maybe change this?
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('You have events happening tomorrow!'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('Failed to fetch events. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching events: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
*/
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back arrow
        title: const Text("Notifications"),
        centerTitle: true, // Center the title 
      ),
     body: isLoading
    ? const Center(child: CircularProgressIndicator())
    : notifications.isEmpty
        ? const Center(child: Text("No new notifications."))
        : ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.event),
                title: Text(notifications[index]),
                subtitle: const Text("Happening tomorrow!"),
              );
            },
          ),
    );
  }
}