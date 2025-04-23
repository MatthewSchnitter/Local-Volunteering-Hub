import 'package:flutter/material.dart';
import 'package:test_drive/main.dart';
import 'package:http/http.dart' as http;
import 'user.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'dart:convert';
import 'base_url.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static final TextEditingController userController = TextEditingController();
  static final TextEditingController passwordController = TextEditingController();
  String baseUrl = UrlHelper.getBaseUrl();//use this in each api call

  int errorNum = 0;
  bool rememberMe = false;
  late http.Response loginResponse;

  bool _obscureLoginText = true;

  String setErrorText() {
    if(errorNum == 0) {
      return "";
    }
    else if (errorNum == 1){
      if(loginResponse.statusCode == 400) {
        final decodedJson = jsonDecode(loginResponse.body);
        String message = decodedJson['message'];
        return "Login error: $message";
      }
      else {
        return "Login error: Internal server error";
      }
    }
    else if (errorNum == 2){
      return "One or more fields are not filled";
    }
    else {
      return "";
    }
  }

  

  Future<http.Response> login(String userName, String password) async {
    String json = '''
    {
      "password": "$password",
      "rememberMe": $rememberMe,
      "userName": "$userName"
    }
    ''';

    // ignore: avoid_print
    //print(json);

    http.Response response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json,
    );
    //http.Response response = await http.post(Uri.parse("https://localhost:7091/login"),
    /*
    http.Response response = await http.post(Uri.parse("https://10.0.2.2:7091/login"),
    headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
    },
    body: json
    );
*/
    //ignore: avoid_print
    print(response.statusCode);
    //ignore: avoid_print
    //print(response.body);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          margin: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _header(context),
              _inputField(context),
              //_forgotPassword(context),
              _signup(context),
            ],
          ),
        ),
      ),
    );
  }

  _header(context) {
    return Column(
      children: [
        
        SizedBox(height: 20), 
        Image.asset(
          'assets/lvh_logo.png', 
          width: MediaQuery.of(context).size.width * 0.4, 
          fit: BoxFit.contain, 
        ),
        SizedBox(height: 30), 
        const Text("Welcome to Local Volunteering Hub!",
        style: TextStyle(
          fontSize: 25,
        ),),
      ],
    );
  }

  _inputField(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        const Center(
            child: Text(
            "Email must be verified in order to log in. If you recently created an account, a verification email was sent to you.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: userController,
          decoration: InputDecoration(
              hintText: "Username or Email",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none
              ),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.person)),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: passwordController,
          decoration: InputDecoration(
            hintText: "Password",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.password),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginText ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureLoginText = !_obscureLoginText;
                });
              },
            ),
          ),
          obscureText: _obscureLoginText,
        ),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Remember Me?",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Checkbox(
              value: rememberMe,
              onChanged: (bool? value) {
                setState(() {
                  rememberMe = value ?? false;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              activeColor: Colors.purple,
              checkColor: Colors.white,
            ),
          ],
        ),
    
        const SizedBox(height: 10),
        
        Center(
          child: Text(
            setErrorText(),
            style: const TextStyle(color: Colors.red),
            ),
        ),
            
        const SizedBox(height: 10),

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
            
            String username = userController.text;
            String password = passwordController.text;

            if(username == "" || password == "") {
              setState(() {
                errorNum = 2;
              });
              Navigator.of(context).pop();
            }
            else {
              loginResponse = await login(username, password);
            

              if(loginResponse.statusCode == 200) {
            
                ApiGetUser? currentUser;
                ApiGetOrg? currentOrg;
                
                try{
                  http.Response userResponse = await http.get(
                    Uri.parse('$baseUrl/api/User/GetUsers'),
                  );
                  
                  if (userResponse.statusCode == 200) {

                    List<ApiGetUser> users = apiGetUserFromJson(userResponse.body);
                    for (ApiGetUser user in users) {
                      if (user.userName == username || user.email == username.toUpperCase()) {
                        currentUser = user;
                        break;
                      }
                    }

                  
                  //check if user is an npo so we can pass in their org info 
                  if(currentUser?.userType == 2){

                    http.Response orgResponse = await http.get(
                      Uri.parse('$baseUrl/api/Organization/GetOrganizations'),
                    );

                  
                    if(orgResponse.statusCode == 200){
                      try{
                        List<ApiGetOrg> orgs = apiGetOrgFromJson(orgResponse.body);
                        for(ApiGetOrg org in orgs){
                          if(org.userId == currentUser?.idNumber){
                            currentOrg = org;
                            break;
                          }
                        }
                      } catch(e){
                        print(e.toString());
                      }
                    }
                  }
                }
                } catch(e) {
                    print(e.toString());
                  }
                
                setState(() {
                  errorNum = 0;
                });
                Navigator.of(context).pop();

                Navigator.of(context).push(
                  MaterialPageRoute(builder: 
                  (context) => MyHomePage(
                    title: 'LVH', 
                    user: currentUser, 
                    org: currentOrg,
                  ),
                  ),
                );
              }
              else {
                Navigator.of(context).pop();
                setState(() {
                  errorNum = 1;
                });
              }
            }
          },

          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.purple,
          ),
          child: const Text(
            "Login",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white
            ),
          ),
        )
      ],
    );
  }

  _forgotPassword(context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                  );
      },
      child: const Text("Forgot password?",
        style: TextStyle(color: Colors.purple),
      ),
    );
  }

  _signup(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        TextButton(
            onPressed: () {
              Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupPage()),
                  );
            },
            child: const Text("Sign Up", style: TextStyle(color: Color.fromARGB(255, 212, 103, 232)),)
        )
      ],
    );
  }

}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPasswordPage> {
  static final TextEditingController oldEmailController = TextEditingController();
  static final TextEditingController oldPasswordController = TextEditingController();
  static final TextEditingController phoneNumberController = TextEditingController();
  static final TextEditingController newPasswordController = TextEditingController();
  static final TextEditingController newEmailController = TextEditingController();

  int errorNum = 0;
  String? userType;
  String baseUrl = UrlHelper.getBaseUrl();//use this in each api call

  String setErrorText() {
    if(errorNum == 0) {
      return "";
    }
    else if (errorNum == 1){
      return "Error";
    }
    else {
      return "";
    }
  }

  Future<int> forgotPassword(String oldEmail, String oldPassword, String phoneNumber,
  String newPassword, String newEmail) async {
    int userTypeNum;
    if(userType == "Volunteer") {
      userTypeNum = 1;
    }
    else if (userType == "Organization") {
      userTypeNum = 2;
    }
    else {
      userTypeNum = 0;
    }
    
    String json = '''
    {
      "email": "$oldEmail",
      "password": "$oldPassword",
      "phoneNumber": "$phoneNumber",
      "userType": "$userTypeNum",
      "preferredContactMethod": "string",
      "oldPassword": "$oldPassword",
      "newPassword": "$newPassword",
      "newEmail": "$newEmail",
      "token": "string"
    }
    ''';

    // ignore: avoid_print
    print(json);
    //http.Response response = await http.post(Uri.parse("https://10.0.2.2:7091/forgotPassword"),

    http.Response response = await http.post(
    Uri.parse('$baseUrl/forgotPassword'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
      body: json,
    );

    

    //ignore: avoid_print
    print(response.statusCode);
    //ignore: avoid_print
    print(response.body);
    return response.statusCode;

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          margin: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _header(context),
              _inputField(context),
              _signup(context),
            ],
          ),
        ),
      ),
    );
  }

  _header(context) {
    return const Column(
      children: [
        Text(
          "Input the following to change password and email",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  _inputField(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        TextField(
          controller: oldEmailController,
          decoration: InputDecoration(
              hintText: "Old Email",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none
              ),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.email)),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: oldPasswordController,
          decoration: InputDecoration(
            hintText: "Old Password",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.password),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 10),

        TextField(
          controller: phoneNumberController,
          decoration: InputDecoration(
            hintText: "Phone Number",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.phone),
          ),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: newPasswordController,
          decoration: InputDecoration(
            hintText: "New Password",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.password),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 10),

        TextField(
          controller: newEmailController,
          decoration: InputDecoration(
            hintText: "New Email",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 10),

        DropdownButtonFormField<String>(
          value: userType,
          decoration: InputDecoration(
            hintText: "Are you a Volunteer or Organization?",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.group),
          ),
          items: <String>['Volunteer', 'Organization']
              .map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              userType = newValue; // Update user type on selection
            });
          },
        ),
        const SizedBox(height: 10),
        
        Center(
          child: Text(
            setErrorText(),
            style: const TextStyle(color: Colors.red),
            ),
        ),
            
        const SizedBox(height: 10),

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

            String oldEmail = oldEmailController.text;
            String oldPassword = oldPasswordController.text;
            String phoneNumber = phoneNumberController.text;
            String newPassword = newPasswordController.text;
            String newEmail = newEmailController.text;
            int code = await forgotPassword(oldEmail.toUpperCase(), oldPassword, phoneNumber, newPassword, newEmail.toUpperCase());
            if(code == 200) {
              
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: 
                (context) => const LoginPage(),
                ),
              );
            }
            else {
              Navigator.of(context).pop();
              setState(() {
                errorNum = 1;
              });
            }
          },

          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.purple,
          ),
          child: const Text(
            "Change",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white
            ),
          ),
        )
      ],
    );
  }

  _signup(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
            onPressed: () {
              Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
            },
            child: const Text("Back", style: TextStyle(color: Colors.purple),)
        )
      ],
    );
  }

}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  static final TextEditingController userController = TextEditingController();
  static final TextEditingController emailController = TextEditingController();
  static final TextEditingController passwordController = TextEditingController();
  static final TextEditingController confirmPassController = TextEditingController();
  static final TextEditingController phoneController = TextEditingController();
  static final TextEditingController firstNameController = TextEditingController();
  static final TextEditingController lastNameController = TextEditingController();
  static final TextEditingController dobController = TextEditingController();
  static final TextEditingController zipController = TextEditingController();
  static final TextEditingController stateController = TextEditingController();
  static final TextEditingController countryController = TextEditingController();
  static final TextEditingController einController = TextEditingController();
  static final TextEditingController orgWebsiteController = TextEditingController();
  static final TextEditingController orgNameController = TextEditingController();
  static final TextEditingController orgPhoneController = TextEditingController();
  static final TextEditingController orgZipController = TextEditingController();
  static final TextEditingController orgStreetController = TextEditingController();
  static final TextEditingController orgCityController = TextEditingController();
  static final TextEditingController orgStateController = TextEditingController();
  static final TextEditingController orgCountryController = TextEditingController();

  final List<MultiSelectItem<int>> _interests = [
    MultiSelectItem(2, 'Environmental Conservation'),
    MultiSelectItem(3, 'Community Service'),
    MultiSelectItem(4, 'Education Tutoring'),
    MultiSelectItem(5, 'Health Wellness'),
    MultiSelectItem(6, 'Youth Development'),
    MultiSelectItem(7, 'Arts & Culture'),
    MultiSelectItem(8, 'Animal Welfare'),
    MultiSelectItem(9, 'Disaster Relief'),
    MultiSelectItem(10, 'Senior Services'),
    MultiSelectItem(11, 'Advocacy & Social Justice'),
    MultiSelectItem(12, 'Sports & Recreation'),
  ];

  List<int> selectedInterests = [];
  String baseUrl = UrlHelper.getBaseUrl();//use this in each api call

  String? userType;
  int errorNum = 0;
  late http.Response createResponse;
  
  String? _stateErrorText;
  String? _orgStateErrorText;

  String? _countryErrorText;
  String? _orgCountryErrorText;
 
  String? _zipErrorText;
  String? _orgZipErrorText;

  String? _phoneErrorText;
  String? _orgPhoneErrorText;

  String? _dobErrorText;

  bool _obscureSignUpInitialText = true;
  bool _obscureSignUpConfirmText = true;
  
  Future<http.Response> createNewUser(String userName, String normalizedEmail, String password, String phone,
  String firstName, String lastName,String dob, String zip, String state, String country, List<int> selectedInterests,
  String ein, String orgWebsite, String orgName, String orgPhone, String orgZip, String orgStreet, String orgCity, String orgState,
  String orgCountry) async {
    int userTypeNum;
    if(userType == "Volunteer") {
      userTypeNum = 1;
    }
    else if (userType == "Organization") {
      userTypeNum = 2;
    }
    else {
      userTypeNum = 0;
    }

    if(selectedInterests.isEmpty) {
      selectedInterests.add(1);
    }
    
    ApiUser user = ApiUser(
    id: "testUser",
    userName: userName,
    normalizedEmail: normalizedEmail.toUpperCase(),
    phoneNumber: phone,
    password: password,
    firstName: firstName,
    lastName: lastName,
    dob: dob,
    zip: zip,
    state: state,
    country: country,
    userType: userTypeNum,
    preferredContactMethod: 1,
    interests: selectedInterests,
    ein: ein,
    orgWebsite: orgWebsite,
    orgName: orgName,
    orgPhone: orgPhone,
    orgZip: orgZip,
    orgStreet: orgStreet,
    orgCity: orgCity,
    orgState: orgState,
    orgCountry: orgCountry,
    npo: 0,
    events: [],
    organization: null,
    volunteer: null
    );


    String body = apiUserToJson(user);
    // ignore: avoid_print
    print(body);
    //http.Response response = await http.post(Uri.parse("https://10.0.2.2:7091/register"),

    http.Response response = await http.post(
    Uri.parse('$baseUrl/register'), // Use the dynamically determined base URL
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: body,
  );

    //ignore: avoid_print
    print(response.statusCode);
    //ignore: avoid_print
    print(response.body);
    return response;

  }

  String setErrorText() {
    if(errorNum == 0) {
      return "";
    }
    else if (errorNum == 1){
      return "Passwords do not match";
    }
    else if(errorNum == 2) {
      if(createResponse.statusCode == 400) {
        final decodedJson = jsonDecode(createResponse.body);
        if (decodedJson.containsKey("")) {
          final List<dynamic> errorList = decodedJson[""]; 
          if (errorList.isNotEmpty) {
            String message = errorList.first; 
            return "Registration error: $message";
          }
        }
        return "Registration error: Unknown error";
      }
      else {
        return "Registration error: Internal server error";
      }
    }
    else if(errorNum == 3) {
      return "Please fill out all organization fields";
    }
    else if(errorNum == 4) {
      return "Zip code must be valid";
    }
    else if(errorNum == 5) {
      return "One or more fields are not filled";
    }
    else {
      return "";
    }
  }

  bool validZip(String input) {
    final RegExp regex = RegExp(r'^\d{5}$');
    return regex.hasMatch(input);
  }

  String? _validateDOB(String value) {
    if (value.length != 10) {
      return "Enter a valid date of birth";
    }
    return null;
  }

  String? _validateZip(String value) {
    if (value.length != 5) {
      return "Enter a valid five number zip code";
    }
    return null;
  }

  String? _validateOrgZip(String value) {
    if (value.length != 5) {
      return "Enter a valid five number zip code";
    }
    return null;
  }

  String? _validatePhone(String value) {
    if (value.length != 12) {
      return "Enter a 10 digit phone number";
    }
    return null;
  }

  String? _validateOrgPhone(String value) {
    if (value.length != 12) {
      return "Enter a 10 digit phone number";
    }
    return null;
  }

  String? _validateCountry(String value) {
    if (value.length != 2) {
      return "Enter a two-letter country code";
    }
    return null;
  }

  String? _validateState(String value) {
    if (value.length != 2) {
      return "Enter a two-letter state code";
    }
    return null;
  }

  String? _validateOrgCountry(String value) {
    if (value.length != 2) {
      return "Enter a two-letter country code";
    }
    return null;
  }

  String? _validateOrgState(String value) {
    if (value.length != 2) {
      return "Enter a two-letter state code";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Column(
                  children: <Widget>[
                    SizedBox(height: 60.0),

                    Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                       height: 20,
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    TextField(
                      controller: userController,
                      decoration: InputDecoration(
                          hintText: "Username",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none),
                          fillColor: Colors.purple.withOpacity(0.1),
                          filled: true,
                          prefixIcon: const Icon(Icons.person)),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                          hintText: "Email",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none),
                          fillColor: Colors.purple.withOpacity(0.1),
                          filled: true,
                          prefixIcon: const Icon(Icons.email)),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        hintText: "Password",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.password),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureSignUpInitialText ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureSignUpInitialText = !_obscureSignUpInitialText;
                            });
                          },
                        ),
                        helperText: "Password must be 8+ characters, include 1 uppercase letter, 1 number, and 1 special character",
                      ),
                      obscureText: _obscureSignUpInitialText,
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: confirmPassController,
                      decoration: InputDecoration(
                        hintText: "Confirm Password",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.password),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureSignUpConfirmText ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureSignUpConfirmText = !_obscureSignUpConfirmText;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureSignUpConfirmText,
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: firstNameController,
                      decoration: InputDecoration(
                        hintText: "First Name",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.abc),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: lastNameController,
                      decoration: InputDecoration(
                        hintText: "Last Name",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.abc),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        hintText: "Phone Number (e.g. 555-555-5555)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.phone),
                        errorText: _phoneErrorText,
                      ),
                      onChanged: (value) {
                      setState(() {
                        _phoneErrorText = _validatePhone(value);
                      });
                      }
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: dobController,
                      decoration: InputDecoration(
                        hintText: "Date of Birth (MM/DD/YYYY)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.cake),
                        errorText: _dobErrorText,
                      ),
                      onChanged: (value) {
                      setState(() {
                        _dobErrorText = _validateDOB(value);
                      });
                      }
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: zipController,
                      decoration: InputDecoration(
                        hintText: "Zip Code",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.numbers),
                        errorText: _zipErrorText,
                      ),
                      onChanged: (value) {
                      setState(() {
                        _zipErrorText = _validateZip(value);
                      });
                      }
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: stateController,
                      decoration: InputDecoration(
                        hintText: "State (e.g. UT)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.abc),
                        errorText: _stateErrorText,
                      ),
                      onChanged: (value) {
                      setState(() {
                        _stateErrorText = _validateState(value);
                      });
                      }
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: countryController,
                      decoration: InputDecoration(
                        hintText: "Country (e.g. US)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.flag),
                        errorText: _countryErrorText,
                      ),
                      onChanged: (value) {
                      setState(() {
                        _countryErrorText = _validateCountry(value);
                      });
                      }
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: userType,
                      decoration: InputDecoration(
                        hintText: "Are you a Volunteer or Organization?",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.group),
                      ),
                      items: <String>['Volunteer', 'Organization']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          userType = newValue; // Update user type on selection
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    MultiSelectDialogField(
                      items: _interests,
                      title: const Text("Interests"),
                      selectedColor: Colors.purple,
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.purple,
                        ),
                      ),
                      buttonIcon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.purple,
                      ),
                      buttonText: const Text(
                        "Select Interests",
                        style: TextStyle(
                          color: Colors.purple,
                          fontSize: 16,
                        ),
                      ),
                      itemsTextStyle: const TextStyle(
                        color: Colors.white, 
                      ),
                      selectedItemsTextStyle: const TextStyle(
                        color: Colors.white,
                      ),
                      onConfirm: (results) {
                        setState(() {
                          selectedInterests = results.cast<int>();
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    if(userType == "Organization") ...[

                    const Center(
                      child: Text(
                        "Fill out the following fields only if you are an organization",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: einController,
                      decoration: InputDecoration(
                        hintText: "EIN",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                    ),

                    const SizedBox(height: 20),
                
                    TextField(
                      controller: orgWebsiteController,
                      decoration: InputDecoration(
                        hintText: "Organization Website",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.web),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: orgNameController,
                      decoration: InputDecoration(
                        hintText: "Organization Name",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.web),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: orgPhoneController,
                      decoration: InputDecoration(
                        hintText: "Organization Phone (e.g. 555-555-5555)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.phone),
                        errorText: _orgPhoneErrorText,
                      ),
                      onChanged: (value) {
                      setState(() {
                        _orgPhoneErrorText = _validateOrgPhone(value);
                      });
                      }
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: orgZipController,
                      decoration: InputDecoration(
                        hintText: "Organization Zip",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.numbers),
                        errorText: _orgZipErrorText,
                      ),
                      onChanged: (value) {
                      setState(() {
                        _orgZipErrorText = _validateOrgZip(value);
                      });
                      }
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: orgStreetController,
                      decoration: InputDecoration(
                        hintText: "Organization Street",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.edit_road),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: orgCityController,
                      decoration: InputDecoration(
                        hintText: "Organization City",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.location_city),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: orgStateController,
                      decoration: InputDecoration(
                        hintText: "Organization State (e.g. UT)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.abc),
                        errorText: _orgStateErrorText,
                      ),
                      onChanged: (value) {
                      setState(() {
                        _orgStateErrorText = _validateOrgState(value);
                      });
                      }
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: orgCountryController,
                      decoration: InputDecoration(
                        hintText: "Organization Country (e.g. US)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.abc),
                        errorText: _orgCountryErrorText,
                      ),
                      onChanged: (value) {
                      setState(() {
                        _orgCountryErrorText = _validateOrgCountry(value);
                      });
                      }
                    ),

                    const SizedBox(height: 20),
                    ]

                  ],
                ),

                const SizedBox(height: 10),

                Center(
                  child: Text(
                    setErrorText(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

                Container(
                    padding: const EdgeInsets.only(top: 3, left: 3),

                    child: ElevatedButton(
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

                        String userName = userController.text;
                        String email = emailController.text;
                        String password = passwordController.text;
                        String confirmedPass = confirmPassController.text;
                        String phone = phoneController.text;
                        String firstName = firstNameController.text;
                        String lastName = lastNameController.text;
                        String dob = dobController.text;
                        String zip = zipController.text;
                        String state = stateController.text;
                        String country = countryController.text;
                        String ein = "";
                        String orgWebsite = "";
                        String orgName = "";
                        String orgPhone = "";
                        String orgZip = "";
                        String orgStreet= "";
                        String orgCity= "";
                        String orgState= "";
                        String orgCountry= "";
                        
                        if(userName == "" || email == "" || password == "" || confirmedPass == "" || phone == "" ||
                        firstName == "" || lastName == "" || dob == "" || zip == "" || state == "" || country == "") {
                            setState(() {
                              errorNum = 5;
                            });
                            Navigator.of(context).pop();
                        }
                        else if(userType == "Organization") {
                          ein = einController.text;
                          orgWebsite = orgWebsiteController.text;
                          orgName = orgNameController.text;
                          orgPhone = orgPhoneController.text;
                          orgZip = orgZipController.text;
                          orgStreet = orgStreetController.text;
                          orgCity = orgCityController.text;
                          orgState = orgStateController.text;
                          orgCountry = orgCountryController.text;
                          if(ein == "" || orgWebsite == "" || orgName == "" || orgPhone == "" ||
                          orgZip == "" || orgStreet == "" || orgCity == "" || orgState == "" || orgCountry == "") {
                            Navigator.of(context).pop();
                            setState(() {
                              errorNum = 5;
                            });
                          }
                          else if(!validZip(orgZip)) {
                            Navigator.of(context).pop();
                            setState(() {
                              errorNum = 4;
                            });
                          }
                        }
                        else if(password != confirmedPass) {
                          Navigator.of(context).pop();
                          setState(() {
                            errorNum = 1;
                          });
                        }
                        else if(!validZip(zip)) {
                          Navigator.of(context).pop();
                            setState(() {
                              errorNum = 4;
                            });
                        }
                        else {
                          createResponse = await createNewUser(userName, email, password, phone, 
                          firstName, lastName, dob, zip, state, country, selectedInterests,
                          ein, orgWebsite, orgName, orgPhone, orgZip, orgStreet, orgCity, orgState,
                          orgCountry);
                          if(createResponse.statusCode == 200) {
                            //http.Response response = await http.get(Uri.parse("https://10.0.2.2:7091/api/User/GetUsers"));
                            http.Response response = await http.get(Uri.parse('$baseUrl/api/User/GetUsers'));

                            ApiGetUser? currentUser;
                            if(response.statusCode == 200) {
                              try{
                              List<ApiGetUser> users = apiGetUserFromJson(response.body);
                              for(ApiGetUser user in users) {
                                if(user.userName == userName) {
                                  currentUser = user;
                                  break;
                                }
                              }
                              } catch(e) {
                                print(e.toString());
                              }
                            }

                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: 
                              (context) => MyHomePage(title: "LVH", user: currentUser))
                            );
                          }
                          else {
                            setState(() {
                              Navigator.of(context).pop();
                              errorNum = 2;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.purple,
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(fontSize: 20,
                        color: Colors.white),
                      ),
                    )
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("Already have an account?"),
                    TextButton(
                        onPressed: () {
                
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                        
                        },
                        child: const Text("Login", style: TextStyle(color: Colors.purple),)
                    )
                  ],
                ),

                const SizedBox(height: 30),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

