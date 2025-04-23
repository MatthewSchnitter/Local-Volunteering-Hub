import 'package:flutter/material.dart';
import 'user.dart';
import 'base_url.dart';
import 'package:http/http.dart' as http;


class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key, this.user, this.org, this.cachedLeaderboardData, this.onCacheLeaderboard, this.cachedVolunteerData, this.onCacheVolunteer});
  final ApiGetUser? user;
  final ApiGetOrg? org;
  final Map<String, Map<String, int>>? cachedLeaderboardData;
  final ValueChanged<Map<String, Map<String, int>>>? onCacheLeaderboard;

  final List<ApiGetUser>? cachedVolunteerData;
  final ValueChanged<List<ApiGetUser>>? onCacheVolunteer;

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  String baseUrl = UrlHelper.getBaseUrl(); //get base url for all api calls here
  late Map<String, Map<String, int>> _leaderboardData;
  late List<ApiGetUser> _volunteers;
  bool _isLoading = true;
  bool _filterByState = false;
  bool _filterByZip = false;


  @override
  void initState() {
    super.initState();
    _leaderboardData = widget.cachedLeaderboardData ?? {};
    _volunteers = widget.cachedVolunteerData ?? [];
    if(_leaderboardData.isEmpty) {
       _fetchVolunteers();
    } else {
      if(mounted) {
      setState(() {
        _isLoading = false;
      });
      }
    }
  }

  Future<void> _fetchVolunteers() async {
    try {
      final volResponse = await http.get(Uri.parse('$baseUrl/api/Volunteer/GetVolunteers'));
      if(volResponse.statusCode == 200) {
        if(mounted) {
        setState(() {
          _volunteers = apiGetUserFromJson(volResponse.body);
          widget.onCacheVolunteer?.call(_volunteers);
        });
      }
        _fetchLeaderboardCounts();
      } else {
        throw Exception('Failed to load volunteers');
      }
    } catch (e) {
      print("Error fetching volunteers: $e");
    }
  }

  Future<void> _fetchLeaderboardCounts() async {
    try {
      for(ApiGetUser volunteer in _volunteers) {
        String id = volunteer.idNumber.toString();
        String? username = volunteer.userName;


        final confirmedResponse = await http.get(Uri.parse('$baseUrl/api/Volunteer/GetConfirmedAttendedEvents?userId=$id'));
        int confirmedCount = 0;
        if (confirmedResponse.statusCode == 200) {
          List<Event> confirmedEvents = welcomeFromJson(confirmedResponse.body);
          confirmedCount = confirmedEvents.length;
        }

        // final unconfirmedResponse = await http.get(Uri.parse('$baseUrl/api/Volunteer/GetUnconfirmedAttendedEvents?userId=$id'));
        // int unconfirmedCount = 0;
        // if (unconfirmedResponse.statusCode == 200) {
        //   List<Event> unconfirmedEvents = welcomeFromJson(unconfirmedResponse.body);
        //   unconfirmedCount = unconfirmedEvents.length;
        // }
        int unconfirmedCount = 0;

        if(mounted) {
        setState(() {
          _leaderboardData[username!] = {
            'confirmed': confirmedCount,
            'unconfirmed': unconfirmedCount,
          };
        });
        }

      }
    } catch (e) {
      print("Error fetching leaderboard data: $e");
    } finally {
      if(mounted) {
      setState(() {
        _isLoading = false;
        widget.onCacheLeaderboard?.call(_leaderboardData);
      });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    List<MapEntry<String, Map<String, int>>> displayedLeaderboardData = _leaderboardData.entries.toList()
    ..sort((a, b) => b.value['confirmed']!.compareTo(a.value['confirmed']!));

    if (_filterByZip && widget.user?.zip != null) {
      displayedLeaderboardData = displayedLeaderboardData.where((entry) {
        final volunteer = _volunteers.firstWhere((v) => v.userName == entry.key);
        return volunteer.zip == widget.user?.zip;
      }).toList();
    }
    else if (_filterByState && widget.user?.state != null) {
      displayedLeaderboardData = displayedLeaderboardData.where((entry) {
        final volunteer = _volunteers.firstWhere((v) => v.userName == entry.key);
        return volunteer.state == widget.user?.state;
      }).toList();
    }

    return Scaffold(
      body:
        SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Center(
                child: Text(
                  "Volunteer Leaderboard",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Attendance for completed events is verified through event check in or by the organization",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Show Volunteers within my:"),
                  const SizedBox(width: 10),
                  const Text("State"),
                  Switch(
                    value: _filterByState,
                    onChanged: (bool value) {
                      if(mounted) {
                      setState(() {
                        _filterByState = value;
                      });
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text("Zip Code"),
                  Switch(
                    value: _filterByZip,
                    onChanged: (bool value) {
                      if(mounted) {
                      setState(() {
                        _filterByZip = value;
                      });
                      }
                    },
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      if(mounted) {
                        setState(() {
                          _isLoading = true;
                          _fetchVolunteers();
                        });
                      }
                    },
                    child: const Text("Reload"),
                  )
                ],
              ),

              const SizedBox(height: 10),
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                  :_leaderboardData.isEmpty
                  ? const Center(child: Text('Unable to fetch leaderboard'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), 
                    padding: const EdgeInsets.all(16.0),
                    itemCount: displayedLeaderboardData.length,
                    itemBuilder: (context, index) {

                      final entry = displayedLeaderboardData[index];
                      final username = entry.key;
                      final counts = entry.value;
                      final confirmedEvents = counts['confirmed']!;
                      //final unconfirmedEvents = counts['unconfirmed']!;

                      Color? rankColor = Colors.purpleAccent;
                      if (index == 0) {
                        rankColor = Colors.amber[400]; // Gold
                      } else if (index == 1) {
                        rankColor = Colors.grey[400]; 
                      }
                      else if (index == 2) {
                        rankColor = Colors.brown[400]; 
                      }

                      TextStyle nameStyle = theme.textTheme.titleMedium!;
                      if (username == widget.user?.userName) {
                        nameStyle = nameStyle.copyWith(fontWeight: FontWeight.bold);
                      }

                      String achievementTitle = "";
                      if (confirmedEvents >= 0 && confirmedEvents <= 4) {
                        achievementTitle = "Volunteer";
                      }
                      else if (confirmedEvents >= 5 && confirmedEvents <= 9) {
                        achievementTitle = "Helping Hand";
                      }
                      else if (confirmedEvents >= 10 && confirmedEvents <= 19) {
                        achievementTitle = "Steady Supporter";
                      }
                      else if (confirmedEvents >= 20 && confirmedEvents <= 29) {
                        achievementTitle = "Service Star";
                      }
                      else if (confirmedEvents >= 30 && confirmedEvents <= 39) {
                        achievementTitle = "Change Maker";
                      }
                      else if (confirmedEvents >= 40 && confirmedEvents <= 49) {
                        achievementTitle = "Community Champion";
                      }
                      else if (confirmedEvents >= 50) {
                        achievementTitle = "Local Legend";
                      }

                      String eventText = "$confirmedEvents events completed";
                      if(confirmedEvents == 1) {
                        eventText = "$confirmedEvents event completed";
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 3,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: rankColor,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: 
                          Row(
                            children: [
                              Text(
                                username,
                                style: nameStyle,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                achievementTitle,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Color.fromARGB(255, 198, 82, 219),
                                ),
                              ),
                            ]
                          ),
                          subtitle: Text(
                            eventText,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      );
                    },
                  ),
                  ]
              )
        )
    );
  }
}