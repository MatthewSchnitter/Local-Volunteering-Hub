


import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import 'base_url.dart';
import 'dart:convert';
import 'user.dart';
import 'package:intl/intl.dart';
import 'package:http_parser/http_parser.dart';



class AddEventPage extends StatefulWidget {
  const AddEventPage({
    this.selectedDay,
    required this.isEditing,
    this.initialName,
    this.initialStreet,
    this.initialCity,
    this.initialZip,
    this.initialState,
    this.description,
    this.initialCountryCode,
    this.initialStartTime,
    this.initialEndTime,
    this.eventLink,
    this.eventDate,
    this.openSlots,
    this.event,
    super.key,
    this.user,
    this.interestList,
  });
  
  final bool isEditing;
  final String? selectedDay;
  final String? initialName;
  final String? initialStreet;
  final String? initialCity;
  final String? initialZip;
  final String? initialState;
  final String? initialCountryCode;
  final String? initialStartTime;
  final String? initialEndTime;
  final String? eventLink;
  final String? description;
  final String? openSlots;
  final String? eventDate;
  final ApiGetUser? user;
  final Event? event;
  final List<Interest>? interestList;

  @override
  _AddEventPageState createState() => _AddEventPageState();
}



class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _eventLinkController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _openSlotsController = TextEditingController();

  String baseUrl = UrlHelper.getBaseUrl(); //get base url for all api calls here
  
  @override
  void initState(){
    super.initState();
    print("Passed interests: ${widget.interestList}");

    if (widget.isEditing) {
      _nameController.text = widget.event!.name;
      _streetController.text = widget.event!.street;
      _cityController.text = widget.event!.city;
      _zipController.text = widget.event!.zip;
      _stateController.text = widget.event!.state;
      _countryCodeController.text = widget.event!.countryCode;
      _openSlotsController.text = widget.event!.openSlots.toString();
      _startTimeController.text = widget.event!.startTime;
      _eventLinkController.text = widget.event!.eventLink!;
      _dateController.text = widget.event!.date;
      _endTimeController.text = widget.event!.endTime;
      _descriptionController.text = widget.event!.description;

    

    } else {
      print("line 76");
      _nameController.text = widget.initialName ?? '';
      _streetController.text = widget.initialStreet ?? '';
      _cityController.text = widget.initialCity ?? '';
      _zipController.text = widget.initialZip ?? '';
      _stateController.text = widget.initialState ?? '';
      _countryCodeController.text = widget.initialCountryCode ?? '';
      _eventLinkController.text = widget.eventLink ?? '';
      _openSlotsController.text = widget.openSlots ?? '';
      _startTimeController.text = widget.initialStartTime ?? '';
      
      if (widget.selectedDay != null) {
      _dateController.text = DateFormat("M/d/yyyy").format(DateTime.parse(widget.selectedDay!));
      }
      else{
        _dateController.text = widget.eventDate ?? '';
      }
      _endTimeController.text = widget.initialEndTime ?? '';
      _descriptionController.text = widget.description ?? '';
    }

    if (widget.interestList != null) {
      _selectedInterestIds.addAll(
        widget.interestList!.map((interest) => interest.interests),
      );
    }
  }

  final List<InterestCategory> _selectedInterestIds = [];

  List<Interest> availableInterests = [
    Interest(id: 1, interests: InterestCategory.none, events: []),
    Interest(id: 2, interests: InterestCategory.environmentalConservation, events: []),
    Interest(id: 3, interests: InterestCategory.communityService, events: []),
    Interest(id: 4, interests: InterestCategory.educationTutoring, events: []),
    Interest(id: 5, interests: InterestCategory.healthWellness, events: []),
    Interest(id: 6, interests: InterestCategory.youthDevelopment, events: []),
    Interest(id: 7, interests: InterestCategory.artsCulture, events: []),
    Interest(id: 8, interests: InterestCategory.animalWelfare, events: []), // Added animalWelfare
    Interest(id: 9, interests: InterestCategory.disasterRelief, events: []),
    Interest(id: 10, interests: InterestCategory.seniorServices, events: []),
    Interest(id: 11, interests: InterestCategory.advocacySocialJustice, events: []),
    Interest(id: 12, interests: InterestCategory.sportsRecreation, events: []),
  ];

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

  Future<void> _uploadEventPhoto(XFile pickedFile) async {
    print("event id: ${widget.event!.id}");
    try {
      String apiUrl = '$baseUrl/UploadImage?userIdNumber=${widget.user!.idNumber}&imageType=1&eventId=${widget.event!.id}';
      print('API URL: $apiUrl');

      // Create FormData
      FormData formData;
      if (kIsWeb) {
        // Web-specific file handling
        final bytes = await pickedFile.readAsBytes();
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: pickedFile.name,
            contentType: MediaType('image', 'jpeg'), // Adjust content type as needed
          ),
        });
      } else {
        // Mobile or desktop file handling
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            pickedFile.path,
            filename: pickedFile.name,
            contentType: MediaType('image', 'jpeg'), // Adjust content type as needed
          ),
        });
      }

      // Print FormData for debugging
      print('FormData fields: ${formData.fields}');
      print('FormData files: ${formData.files}');

      // Initialize Dio and set headers
      final dio = Dio();
      dio.options.headers['accept'] = '*/*'; // Ensure the 'accept' header matches API expectations
      dio.options.headers['Content-Type'] = 'multipart/form-data';

      // Send POST request
      final response = await dio.post(apiUrl, data: formData);

      // Debug response
      print('Response status code: ${response.statusCode}');
      print('Response data: ${response.data}');

      // Handle response
      handleResponse(response);
    } catch (e) {
      print("Upload error: $e");
    }
  }

  void handleResponse(Response response) {
    if (response.statusCode == 200) {
      print("Uploaded successfully");
      // Perform any additional success handling here
    } else {
      print("Upload failed: ${response.statusCode} - ${response.data}");
      // Perform any error-specific handling here
    }
  }


  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await _uploadEventPhoto(pickedFile);
    } else {
      print("No image selected.");
    }
  }


  Future<void> deleteEvent(int? idEvent) async {
    var url = Uri.parse("$baseUrl/api/Event/DeleteEvent/$idEvent");
    try {
      var response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print("Event deleted. ${response.body}");
        if (mounted) {
          Navigator.pop(context, true);
        }
        homePageKey.currentState?.fetchEvents();

      } else {
        print("Failed to delete event: ${response.statusCode}");
        Navigator.pop(context, true);
        homePageKey.currentState?.fetchEvents();
      }
    } catch (e) {
      print("Error deleting event: $e");
    }
  }

  Future<void> postEvent(EventDTO event) async {
    var url = Uri.parse("$baseUrl/api/Event/CreateEvent");
    var eventData = event.toJson();
    print(eventData);
    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(eventData),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print("Event posted successfully: ${response.body}");
        if (mounted) {
          Navigator.pop(context, true);
        }
        homePageKey.currentState?.fetchEvents();

      } else {
        print("Failed to post event: ${response.statusCode}");
      }
    } catch (e) {
      print("Error posting event: $e");
    }
  }

  Future<void> editEvent(EventDTO event, List<InterestCategory> interestCategories) async {
    var eventUrl = Uri.parse("$baseUrl/api/Event/UpdateEvent");
    var interestUrl = Uri.parse("$baseUrl/api/Event/UpdateEventInterests?eventId=${widget.event!.id}");

    var eventData = event.toJson();

    try {
      // Update the event
      var eventResponse = await http.put(
        eventUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(eventData),
      );

      if (eventResponse.statusCode == 201 || eventResponse.statusCode == 200) {
        print("Event edited successfully: ${eventResponse.body}");

        // Map InterestCategory to the required JSON format
        List<Map<String, dynamic>> interestsPayload = interestCategories.map((category) {
          int categoryId = interestCategoryMap.entries
              .firstWhere((entry) => entry.value == category)
              .key; // Map InterestCategory to its ID

          return {
            "id": 0, // Always 0 as specified in the format
            "eventInterestId": categoryId, // Mapped interest ID
            "eventsId": widget.event!.id // Current event ID
          };
        }).toList();

        // Update the event interests
        var interestsResponse = await http.put(
          interestUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(interestsPayload),
        );

        if (interestsResponse.statusCode == 201 || interestsResponse.statusCode == 200) {
          print("Event interests updated successfully: ${interestsResponse.body}");
        } else {
          print("Failed to update event interests: ${interestsResponse.statusCode}");
          print("Response: ${interestsResponse.body}");
        }

        // Navigate back to the previous page
        if (mounted) {
          Navigator.pop(context, true);
        }
        homePageKey.currentState?.fetchEvents();
      } else {
        print("Failed to edit event: ${eventResponse.statusCode}");
        print("Response: ${eventResponse.body}");
      }
    } catch (e) {
      print("Error editing event: $e");
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(), 
    );

    if (selectedTime != null) {
      final formattedTime = _formatTime(selectedTime);
      controller.text = formattedTime; 
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod; 
    final minute = time.minute < 10 ? '0${time.minute}' : time.minute.toString();
    final amPm = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $amPm';
  }
  
  @override
  Widget build(BuildContext context) {
    int? editEventId;
    int? editHostId;
    if(widget.isEditing){
      editEventId = widget.event?.id;
      editHostId = widget.event?.host;
    }
    else{
      editEventId = 0;
      editHostId = widget.user?.idNumber;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('LVH'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
        children: [
          Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Event Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the event name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date'),
                readOnly: false, // Always editable
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    _dateController.text = DateFormat("M/d/yyyy").format(pickedDate);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select the event date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Street'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the street';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zipController,
                decoration: const InputDecoration(labelText: 'ZIP Code'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the ZIP code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'State'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the state';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryCodeController,
                decoration: const InputDecoration(labelText: 'Country Code'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the country code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder()
                ),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
              
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _eventLinkController,
                decoration: const InputDecoration(labelText: 'Link to event sign up page (optional)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _openSlotsController,
                decoration: const InputDecoration(labelText: 'Open Slots'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  }
                  return null;
                },
              ),
               const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectTime(context, _startTimeController),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _startTimeController,
                    decoration: const InputDecoration(labelText: 'Start Time (hh:mm AM/PM)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the start time';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectTime(context, _endTimeController),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _endTimeController,
                    decoration: const InputDecoration(labelText: 'End Time (hh:mm AM/PM)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the end time';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              // const SizedBox(height: 16),
              // if (_selectedImages.isNotEmpty)
              //   GridView.builder(
              //     shrinkWrap: true,
              //     itemCount: _selectedImages.length,
              //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              //       crossAxisCount: 3,
              //       crossAxisSpacing: 4.0,
              //       mainAxisSpacing: 4.0,
              //     ),
              //     itemBuilder: (context, index) {
              //       return Image.file(
              //         _selectedImages[index],
              //         fit: BoxFit.cover,
              //       );
              //     },
              //   ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Interests:'),
                  ...InterestCategory.values
                      .where((category) => category != InterestCategory.none) //exclude none
                      .map((category) {
                    return CheckboxListTile(
                      title: Text(interestCategoryNames[category] ?? 'Unknown Interest'),
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

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Add Photos'),
              ),
              if(widget.isEditing)
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        deleteEvent(widget.event?.id);
                      },
                    ),
                  ]
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  print(_selectedInterestIds);
                  if (_formKey.currentState!.validate()) {
                    int openSls = int.tryParse(_openSlotsController.text) ?? 0; // Parse open slots

                    EventDTO newEvent = EventDTO(
                      id: editEventId, // Set to 0 or leave to be auto-generated by the server
                      name: _nameController.text,
                      street: _streetController.text,
                      city: _cityController.text,
                      zip: _zipController.text,
                      state: _stateController.text,
                      countryCode: _countryCodeController.text,
                      startTime: _startTimeController.text,
                      endTime: _endTimeController.text,
                      eventLink: _eventLinkController.text,
                      date: _dateController.text, // Ensure the date is in the correct format
                      description: _descriptionController.text, // You might want to capture this field too
                      openSlots: openSls, // Set an appropriate value for open slots
                      host: editHostId, 
                      interest: _selectedInterestIds,
                    );
                    if(widget.isEditing){
                      editEvent(newEvent, _selectedInterestIds);
                    }
                    else{
                      postEvent(newEvent);
                    }
                    
                  }
                },
                child: const Text('Submit'),
              )
            ],
          ),
        ),
        ]
        )
        
      ),
    );
  }

  // @override
  // void dispose() {
  //   _dateController.dispose();
  //   super.dispose();
  // }
}