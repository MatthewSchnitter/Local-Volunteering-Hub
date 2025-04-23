import 'package:flutter/material.dart';
import 'package:test_drive/user.dart';
import 'dart:convert';
import 'package:test_drive/utils.dart';
import 'base_url.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class OrganizerPage extends StatefulWidget {
  final ApiGetOrg organization;
  final ApiGetUser user;
  final String? profileImageUrl;
  final String initials;

  const OrganizerPage({super.key, required this.organization, required this.user, this.profileImageUrl, required this.initials});

  @override
  _OrganizerPageState createState() => _OrganizerPageState();
}

class _OrganizerPageState extends State<OrganizerPage> {
  List<Event> orgEvents = [];
  bool _isLoading = true;
  String baseUrl = UrlHelper.getBaseUrl(); //get base url for all api calls here

  @override
  void initState() {
    super.initState();
    fetchOrgEvents();
  }

  Future<void> fetchOrgEvents() async {
    final hostId = widget.organization.userId;
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/Event/GetEventsByHost?hostId=$hostId'));
      if (response.statusCode == 200) {
        List<dynamic> eventData = json.decode(response.body);
        setState(() {
          orgEvents = eventData.map((json) => Event.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load events');
      }
    } catch (error) {
      print('Error fetching organization events: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? oName = widget.organization.orgName;
    String? phoneNumber = widget.organization.phone;
    String? website = widget.organization.website;
    String? city = widget.organization.city;
    String? state = widget.organization.state;
    String? countryCode = widget.organization.countryCode;

    return Scaffold(
      appBar: AppBar(
        title: Text('$oName'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // const Text(
                  //   'Organization Information',
                  //   style: TextStyle(
                  //     fontSize: 30,
                  //     fontWeight: FontWeight.bold,
                  //     decoration: TextDecoration.underline,
                  //   ),
                  // ),
                  CircleAvatar(
                    radius: 75,
                    backgroundColor: Colors.purple, // Set your desired background color
                    backgroundImage: widget.profileImageUrl != null
                      ? NetworkImage(
                          widget.profileImageUrl!,
                        )
                      : null,
                  child: widget.profileImageUrl == null
                      ? Text(
                          widget.initials, 
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        )
                      : null, 
                  ),
                  const SizedBox(height: 10), 
                  Text(oName ?? "N/A", style: const TextStyle(fontSize: 28)),
                  Text('Phone: ${phoneNumber ?? "N/A"}', style: const TextStyle(fontSize: 18)),
                  InkWell(
                    onTap: () async {
                      if (website != null) {
                        final Uri url = Uri.parse(website);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          print('Could not launch $website');
                        }
                      }
                    },
                    child: Text(
                      'Website: ${website ?? "N/A"}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text('City: ${city ?? "N/A"} ${state ?? "N/A"}, $countryCode', style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                'Upcoming events',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : orgEvents.isEmpty
                    ? const Center(child: Text('No events found.'))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: orgEvents.length,
                        itemBuilder: (context, index) {
                          final event = orgEvents[index];
                          return Card(
                            child: ListTile(
                              title: Text(event.name),
                              subtitle: Text('Date: ${event.date}'),
                              trailing: TextButton(
                                onPressed: () => showEventDetails(
                                    context, event, widget.user, widget.organization, isRegisteredEvent: false),
                                child: const Text('View Details'),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}


