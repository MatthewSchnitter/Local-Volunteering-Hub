// import 'package:flutter/material.dart';
// //import 'package:test_drive/cause_boxes.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:test_drive/main.dart';
import 'user.dart';
import 'sign_up.dart';
import 'base_url.dart';
import 'package:http/http.dart' as http;

class EditProfile extends StatefulWidget {
  const EditProfile({super.key, required this.user, this.org});
  final ApiGetUser user;
  final ApiGetOrg? org;

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController zipController = TextEditingController();
  final TextEditingController userTypeController = TextEditingController();
  final TextEditingController changePassEmail = TextEditingController();
  final TextEditingController changePassOld = TextEditingController();
  final TextEditingController changePassNew = TextEditingController();
  final TextEditingController changePassConfirmNew = TextEditingController();

  int passwordErrorNum = 0;
  late http.Response passwordResponse;

  int deleteErrorNum = 0;
  late http.Response deleteResponse;

  final List<MultiSelectItem<int>> _weekday = [
    MultiSelectItem(1, 'Monday'),
    MultiSelectItem(2, 'Tuesday'),
    MultiSelectItem(3, 'Wednesday'),
    MultiSelectItem(4, 'Thursday'),
    MultiSelectItem(5, 'Friday'),
    MultiSelectItem(6, 'Saturday'),
    MultiSelectItem(7, 'Sunday'),
  ];

  int? selectedDay;

  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();

  int availabilityErrorNum = 0;
  late http.Response availabilityResponse;

  bool _obscureCurrentText = true;
  bool _obscureNewText = true;
  bool _obscureConfirmText = true;


  //I also want to add the ability to change preferences here, not implemented yet
  final String baseUrl = UrlHelper.getBaseUrl(); //get base url for all api calls here

 @override
  void initState() {
    super.initState();
    // Initialize the controllers with user data
    firstNameController.text = "${widget.user.firstName}"; 
    lastNameController.text = "${widget.user.lastName}"; 
    emailController.text = "${widget.user.email}"; 
    phoneController.text = "${widget.user.phoneNumber}"; 
    countryController.text = "${widget.user.country}"; 
    stateController.text = "${widget.user.state}";
    zipController.text = "${widget.user.zip}"; 

    String uType = (widget.user.userType == 1) ? "Volunteer" : "Organization";
    userTypeController.text = uType; 
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
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
                await deleteAccount(); 
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
                return Column(
                children: [
                  const Text('Input the following to change password'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: changePassEmail,
                    decoration: InputDecoration(
                      hintText: "Email",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none),
                      fillColor: Colors.purple.withOpacity(0.1),
                      filled: true,
                      prefixIcon: const Icon(Icons.mail),
                    )
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: changePassOld,
                    decoration: InputDecoration(
                      hintText: "Current Password",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none),
                      fillColor: Colors.purple.withOpacity(0.1),
                      filled: true,
                      prefixIcon: const Icon(Icons.password),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentText ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureCurrentText = !_obscureCurrentText;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureCurrentText,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: changePassNew,
                    decoration: InputDecoration(
                      hintText: "New Password",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none),
                      fillColor: Colors.purple.withOpacity(0.1),
                      filled: true,
                      prefixIcon: const Icon(Icons.password),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewText ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewText = !_obscureNewText;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureNewText,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: changePassConfirmNew,
                    decoration: InputDecoration(
                      hintText: "Confirm New Password",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none),
                      fillColor: Colors.purple.withOpacity(0.1),
                      filled: true,
                      prefixIcon: const Icon(Icons.password),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmText ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmText = !_obscureConfirmText;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmText,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      setPasswordErrorText(),
                      style: const TextStyle(color: Colors.red),
                      ),
                  ),
                ],
              );
            },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); 
                await changePassword(); 
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  String setPasswordErrorText() {
    if(passwordErrorNum == 0) {
      return "";
    }
    else if(passwordErrorNum == 1) {
      return "New passwords do not match";
    }
    else if (passwordErrorNum == 2){
      if(passwordResponse.statusCode == 400) {
        final decodedJson = jsonDecode(passwordResponse.body);
        String message = decodedJson['message'];
        return "Error changing password: $message";
      }
      else {
        return "Error changing password: Internal server error";
      }
    }
    else if (passwordErrorNum == 3) {
      return "One or more fields are not filled";
    }
    else {
      return "";
    }
  }

  Future<void> changePassword() async {
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
      String email = changePassEmail.text;
      String oldPass = changePassOld.text;
      String newPass = changePassNew.text;
      String confirmNewPass = changePassConfirmNew.text;

      if(email == "" || oldPass == "" || newPass == "" || confirmNewPass == "") {
        Navigator.of(context).pop(); // Close loading dialog
        setState(() {
          passwordErrorNum = 3;
        });
        _showChangePasswordDialog();
      }
      else if(newPass != confirmNewPass) {
        Navigator.of(context).pop(); // Close loading dialog
        if(mounted) {
        setState(() {
          passwordErrorNum = 1;
        });
        }
        _showChangePasswordDialog();
      }
      else{
        passwordResponse = await http.put(
          Uri.parse("$baseUrl/changePassword?emailAddress=$email&oldPassword=$oldPass&newPassword=$newPass"),
        );
        print(passwordResponse.body);
        if (passwordResponse.statusCode == 200) {
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          Navigator.of(context).pop(); // Close loading dialog
          if(mounted) {
          setState(() {
            passwordErrorNum = 2;
          });
           _showChangePasswordDialog();
          }
        }
      }
      
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      if(mounted) {
      setState(() {
          passwordErrorNum = 2;
        });
        _showChangePasswordDialog();
      }
    }
  }

  Future<void> deleteAccount() async {
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
      var email = widget.user.email;
      String json = '''
      {
        "email": "$email"
      }
      ''';

      http.Response response = await http.delete(
        Uri.parse("$baseUrl/deleteUser"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json,
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        Navigator.of(context).pop(); // Close loading dialog
        print('Failed to delete account. Status code: ${response.statusCode}');
      }
      
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      print('Error deleting account: $e');
    }
  }

  String setAvailabilityErrorText() {
    if(availabilityErrorNum == 0) {
      return "";
    }
    else if(availabilityErrorNum == 1) {
      return "Please select a day";
    }
    else if(availabilityErrorNum == 2) {
      return "Please set valid start and end times";
    }
    else if (availabilityErrorNum == 3){
      if(availabilityResponse.statusCode == 400) {
        final decodedJson = jsonDecode(availabilityResponse.body);
        String message = decodedJson['message'];
        return "Error adding availability: $message";
      }
      else {
        return "Error adding availability: Internal server error";
      }
    }
    else {
      return "";
    }
  }

  DateTime parseTime(String time) {
    final cleanedTime = time.replaceAll(RegExp(r'\s+'), ' ').trim();
    final format = DateFormat("hh:mm aaa");
    return format.parse(cleanedTime);
  }

  Future<void> addAvailability() async {
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
      String startTime = startTimeController.text;
      String endTime = endTimeController.text;

      if(selectedDay == null) {
        Navigator.of(context).pop(); // Close loading dialog
        setState(() {
          availabilityErrorNum = 1;
        });
        _showVolunteerAvailabilityDialog();
      }
      else if(startTime == "" || endTime == "") {
        Navigator.of(context).pop(); // Close loading dialog
        setState(() {
          availabilityErrorNum = 2;
        });
        _showVolunteerAvailabilityDialog();
      }
      else if(parseTime(startTime).isAfter(parseTime(endTime)) || parseTime(startTime).isAtSameMomentAs(parseTime(endTime))) {
        Navigator.of(context).pop(); // Close loading dialog
        setState(() {
          availabilityErrorNum = 2;
        });
        _showVolunteerAvailabilityDialog();
      }
      else{

        
        var volunteerId = widget.user.idNumber;

        String json = '''
        {
          "dayOfWeek": "$selectedDay",
          "startTime": "$startTime",
          "endTime": "$endTime",
          "volunteer": "$volunteerId"
        }
        ''';


        availabilityResponse = await http.post(
          Uri.parse("$baseUrl/AddVolunteerAvailability"),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: json,
        );
        print(availabilityResponse.body);
        if (availabilityResponse.statusCode == 200) {
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => MyHomePage(title: "LVH", user: widget.user, org: widget.org, index: 5)),
          );
        } else {
          Navigator.of(context).pop(); // Close loading dialog
          setState(() {
            availabilityErrorNum = 3;
            _showVolunteerAvailabilityDialog();
          });
        }
      }
      
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      setState(() {
        availabilityErrorNum = 3;
        _showVolunteerAvailabilityDialog();
      });
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

  void _showVolunteerAvailabilityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add an available time block'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Column(
                    children: _weekday.map((day) {
                      return RadioListTile<int>(
                        title: Text(day.label),  
                        value: day.value,
                        groupValue: selectedDay,
                        onChanged: (value) {
                          setState(() {
                            selectedDay = value!;
                          });
                        },
                        activeColor: Colors.purple,
                        //fillColor: WidgetStateProperty.all(Colors.purple),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _selectTime(context, startTimeController),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: startTimeController,
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
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _selectTime(context, endTimeController),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: endTimeController,
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
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      setAvailabilityErrorText(),
                      style: const TextStyle(color: Colors.red),
                      ),
                  ),
                ],
              );
            },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); 
                await addAvailability(); 
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.user.userName}"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                children: [
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _showDeleteAccountDialog,
                      child: const Text('Delete Account')
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _showChangePasswordDialog, 
                      child: const Text('Change Password')
                    ),
                    const SizedBox(width: 10),
                    if(widget.user.userType == 1) ...[
                      ElevatedButton(
                        onPressed: _showVolunteerAvailabilityDialog, 
                        child: const Text('Add Availability')
                      )
                    ]

                  ]
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: "First Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: "Last Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: "Phone",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: countryController,
                  decoration: const InputDecoration(
                    labelText: "Country",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stateController,
                  decoration: const InputDecoration(
                    labelText: "State",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: zipController,
                  decoration: const InputDecoration(
                    labelText: "Zip Code",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                //not sure how to go about editing the usertype, so this is temp - Isaac
                TextField(
                  controller: userTypeController,
                  decoration: const InputDecoration(
                    labelText: "User Type",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {

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

                    widget.user.firstName = firstNameController.text;
                    widget.user.lastName = lastNameController.text;
                    widget.user.email = emailController.text;
                    widget.user.phoneNumber = phoneController.text;
                    widget.user.country = countryController.text;
                    widget.user.state = stateController.text;
                    widget.user.zip = zipController.text;
                    widget.user.userType = userTypeController.text == "Volunteer" ? 1 : 2;

                    String json = apiGetSingleUserToJson(widget.user);
                    // ignore: avoid_print
                    print(json);
                    http.Response response = await http.put(Uri.parse("$baseUrl/api/User/UpdateUser"),
                    headers: <String, String> {
                        'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: json
                    );

                    //ignore: avoid_print
                    print(response.statusCode);
                    //ignore: avoid_print
                    print(response.body);

                    if (response.statusCode == 200) {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => MyHomePage(title: "LVH", user: widget.user, org: widget.org, index: 5)),
                      );
                    } else {
                      Navigator.of(context).pop();
                      print('Failed to save changes. Status code: ${response.statusCode}');
                    }

                  },
                  child: const Text("Save Changes"),
                ),
                const SizedBox(height: 38),
              
              ],
            ),
          ],
        ),
      ),
    );
  }
}