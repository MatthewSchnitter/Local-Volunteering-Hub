import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'user.dart';
import 'package:intl/intl.dart';
import 'add_event_page.dart';
import 'utils.dart';
import 'base_url.dart';
import 'package:http/http.dart' as http;


class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, this.user, this.org, required this.searchRadius, required this.onRadiusChanged});
  final ApiGetUser? user;
  final ApiGetOrg? org;
  final int searchRadius;
  final ValueChanged<int> onRadiusChanged;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDay;
  late DateTime today;
  String baseUrl = UrlHelper.getBaseUrl(); //get base url for all api calls here

  Map<DateTime, List<Event>> events = {};
  List<Event>? _apiEvents = [];
  late int _searchRadius;

  //final TextEditingController _eventController = TextEditingController();
  late final ValueNotifier<List<Event>> _selectedEvents;
  //int _selectedIndex = 0; // Index for bottom navigation bar items

  @override
  void initState(){
    super.initState();
    today = DateTime.now();
    _selectedDay = today;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay)); //CHANGED THIS FOR TESTING
    _searchRadius = widget.searchRadius;
    _getData(); //COMMENT OUT FOR TESTING
  }

  void _getData() async {
    _apiEvents = (await getEventsInRadius(_searchRadius));
    //print("api events: ${_apiEvents}");
    if(mounted){setState(() {});}
  }

  //gets events within the given radius
  Future<List<Event>?> getEventsInRadius(int radius) async {
    try {
      //print("radius: $radius");
      String userZip = widget.user?.zip ?? 'default-zip'; // i will provide  a default value if zip is null
      var url = Uri.parse("$baseUrl/api/Event/GetEventsInGivenRadius/$userZip/$radius");
      
      
      var response = await http.get(url);
      print("${response.statusCode}");
      if (response.statusCode == 200) {
        //print(response.body);
        List<Event> model = welcomeFromJson(response.body);
        return model;
      }
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<void> _showRadiusDialog() async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      double tempRadius = _searchRadius.toDouble();
      return AlertDialog(
        title: const Text('Set Search Radius (miles)'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current Radius: $tempRadius miles'),
                Slider(
                  value: tempRadius,
                  min: 5,
                  max: 500,
                  divisions: 19,
                  label: tempRadius.round().toString(),
                  onChanged: (double value) {
                    setDialogState(() {
                      tempRadius = value.round().toDouble();
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() {
                _searchRadius = tempRadius.toInt();
              });
              widget.onRadiusChanged(_searchRadius);
              _getData();
            },
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );
}

  Future<List<Event>?> getEvents() async {
    try {
      var url = Uri.parse("$baseUrl/api/Event/GetEvents");
      var response = await http.get(url);
      if (response.statusCode == 200) {


        List<Event> model = welcomeFromJson(response.body);
        
        //print("parsed: $model"); 

        return model;
        
      }
    } catch (e) {
      // ignore: avoid_print
      print(e.toString());
    }
    return null;
  }

  List<Event> getEventDay(day) {
    List<Event> list = [];

    String selectedDayFormatted = DateFormat("M/d/yyyy").format(day);
    //print("in getEventDay, Selected Day: $selectedDayFormatted");
    for (Event event in _apiEvents!) {
 
      //print("API Event Date: ${event.date} - Selected Day: $selectedDayFormatted");
      if (event.date == selectedDayFormatted) {
        list.add(event);
      }
    }
    //print("Events for the selected day: ${list.length}");
    return list;
  }

  List<Event> _getEventsForDay(DateTime day){
    if (_apiEvents == null || _apiEvents!.isEmpty) {
      return [];
    }
    return getEventDay(day);
  }

  void _onDaySelected(DateTime day, DateTime focusedDay){
    if(!isSameDay(_selectedDay, day)){
      setState((){
        _selectedDay = day;
        _selectedEvents.value = _getEventsForDay(_selectedDay);
        //print("Selected Day: $_selectedDay, Events: ${_selectedEvents.value.length}");
      });
    }
  }

  Widget _buildDay(BuildContext context, DateTime day, DateTime focusedDay) {
    final isSelected = isSameDay(_selectedDay, day);
    //final isHovered = isSameDay(focusedDay, day);
    final isToday = isSameDay(today, day);

    final containerDecoration = BoxDecoration(
      color: isSelected
          ? Colors.blueAccent
          : Colors.transparent,
        border: Border.all(color: isSelected ? const Color.fromARGB(255, 87, 134, 205) : Colors.transparent),
        borderRadius: BorderRadius.circular(25),
    );

    final textStyle = TextStyle(
      decoration: isToday && !isSelected ? TextDecoration.underline : TextDecoration.none, // Underline for current day when not selected
      color: isToday ? const Color.fromARGB(255, 237, 234, 234) : const Color.fromARGB(255, 249, 242, 242), // Color for day text
    );

    return Container(
      decoration: containerDecoration,
      child: InkWell(
        onTap: () => _onDaySelected(day, focusedDay),
        child: Center(
          child: Text(
            '${day.day}',
            style: textStyle,
            ),
        ),
      ),
    );
  }


  //CALENDAR PAGE
  @override
  Widget build(BuildContext context){
    return Padding( 
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: ElevatedButton(
              onPressed: _showRadiusDialog,
              child: Text('Showing events within a $_searchRadius mile radius'),
            ),
          ),
          TableCalendar(
            locale: "en_US",
            headerStyle: 
              const HeaderStyle(formatButtonVisible: false,titleCentered: true),
              availableGestures: AvailableGestures.all,
            focusedDay: _selectedDay, 
            firstDay: DateTime.utc(2024, 1, 1), 
            lastDay: DateTime.utc(2030, 3, 14),
            selectedDayPredicate: (day)=>isSameDay(day, today),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders(
              defaultBuilder: _buildDay,
              todayBuilder: (context, day, focusedDay) {
                return _buildDay(context, day, focusedDay);
              },
              markerBuilder: (context, day, events) {
              if (events.isNotEmpty) {
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.map((event) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        width: 6.0,
                        height: 6.0,
                        decoration: BoxDecoration(
                          color: Colors.blue, // Customize the dot color
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              }
              return null;
            },
            ),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ValueListenableBuilder<List<Event>>(
                valueListenable: _selectedEvents, 
                builder:(context, value, _) {
                  return ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index){
                      final event = value[index];
                      //print("value[index]: ${event.id}");
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(border: Border.all(),
                        borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          // ignore: avoid_print
                          onTap: () => showEventDetails(context, event, widget.user, widget.org, isRegisteredEvent: false), //OPEN UP LARGER EVENT INFO PAGE HERE
                          title: Text(value[index].name),
                        ),
                      );
                    });
                  }
                ),
              ),
              //THIS IS THE ADD EVENT BUTTON HEREEEEE
              Tooltip(
                message: 'Add Event',
                child: FloatingActionButton(
                  onPressed: () async {
                    print(_selectedDay.toIso8601String());
                    final eventDetails = await Navigator.of(context).push(
                      MaterialPageRoute(
                        
                        builder: (context) => AddEventPage(selectedDay: _selectedDay.toIso8601String(), isEditing: false, user: widget.user),
                      ),
                    );

                    _apiEvents = await getEventsInRadius(_searchRadius);
                    _selectedEvents.value = _getEventsForDay(_selectedDay);

                    if (eventDetails != null) {
                      setState(() {

                        //HOW TO GET THESE VALUES??
                        int eventId = 1;
                        int host = 1;
                        int openSlots = 1;

                        _apiEvents!.add(
                          Event(
                            id: eventId,
                            name: eventDetails['name'],
                            street: eventDetails['street'],
                            city: eventDetails['city'],
                            zip: eventDetails['zip'],
                            state: eventDetails['state'],
                            countryCode: eventDetails['countryCode'],
                            startTime: eventDetails['startTime'],
                            endTime: eventDetails['endTime'],
                            date: eventDetails['date'],
                            eventLink: eventDetails['eventURL'],
                            openSlots: openSlots,
                            host: host,
                            description: eventDetails['description'],
                            hostNavigation: "dummydata", //dummy data here for now
                          ),
                        );
                        _selectedEvents.value = _getEventsForDay(_selectedDay);
                      });
                    }
                  },
                child: const Icon(Icons.add),
              )
              )
        ],
      ),
    );
  }
}