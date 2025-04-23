// To parse this JSON data, do
//
//     final apiUser = apiUserFromJson(jsonString);

import 'dart:convert';

List<ApiUser> apiUserFromJson(String str) => List<ApiUser>.from(json.decode(str).map((x) => ApiUser.fromJson(x)));

String apiUserToJson(ApiUser data) => json.encode(data.toJson());

List<Event> welcomeFromJson(String str) => List<Event>.from(json.decode(str).map((x) => Event.fromJson(x)));

String welcomeToJson(List<Event> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ApiUser {
    String id;
    String userName;
    String normalizedEmail;
    String phoneNumber;
    String password;
    String firstName;
    String lastName;
    String dob;
    String zip;
    String state;
    String country;
    int userType;
    int preferredContactMethod;
    List<int> interests;
    String ein;
    String orgWebsite;
    String orgName;
    String orgPhone;
    String orgZip;
    String orgStreet;
    String orgCity;
    String orgState;
    String orgCountry;
    int? npo = 0;
    List<Event>? events;
    Organization? organization;
    Volunteer? volunteer;

    ApiUser({
        required this.id,
        required this.userName,
        required this.normalizedEmail,
        required this.phoneNumber,
        required this.password,
        required this.firstName,
        required this.lastName,
        required this.dob,
        required this.zip,
        required this.state,
        required this.country,
        required this.userType, //0 is admin, 1 is volunteer, 2 is organization
        required this.preferredContactMethod,
        required this.interests,
        required this.ein,
        required this.orgWebsite,
        required this.orgName,
        required this.orgPhone,
        required this.orgZip,
        required this.orgStreet,
        required this.orgCity,
        required this.orgState,
        required this.orgCountry,
        this.npo,
        this.events,
        this.organization,
        this.volunteer,
    });

    factory ApiUser.fromJson(Map<String, dynamic> json) => ApiUser(
        id: json["id"],
        userName: json["userName"],
        normalizedEmail: json["normalizedEmail"],
        phoneNumber: json["phoneNumber"],
        password: json["password"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        dob: json["dob"],
        zip: json["zip"],
        state: json["state"],
        country: json["country"],
        userType: json["userType"],
        preferredContactMethod: json["preferredContactMethod"],
        interests: List<int>.from(json["interests"].map((x) => x)),
        ein: json["ein"],
        orgWebsite: json["orgWebsite"],
        orgName: json["orgName"],
        orgPhone: json["orgPhone"],
        orgZip: json["orgZip"],
        orgStreet: json["orgStreet"],
        orgCity: json["orgCity"],
        orgState: json["orgState"],
        orgCountry: json["orgCountry"],
        npo: json["npo"],
        events: List<Event>.from(json["events"].map((x) => Event.fromJson(x))),
        organization: Organization.fromJson(json["organization"]),
        volunteer: Volunteer.fromJson(json["volunteer"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "userName": userName,
        "normalizedEmail": normalizedEmail,
        "phoneNumber": phoneNumber,
        "password": password,
        "firstName": firstName,
        "lastName": lastName,
        "dob": dob,
        "zip": zip,
        "state": state,
        "country": country,
        "userType": userType,
        "preferredContactMethod": preferredContactMethod,
        "interests": List<dynamic>.from(interests.map((x) => x)),
        "ein": ein,
        "orgWebsite": orgWebsite,
        "orgName": orgName,
        "orgPhone": orgPhone,
        "orgZip": orgZip,
        "orgStreet": orgStreet,
        "orgCity": orgCity,
        "orgState": orgState,
        "orgCountry": orgCountry,
        "npo": npo,
        "events": List<dynamic>.from(events!.map((x) => x.toJson())),
        "organization": organization?.toJson(),
        "volunteer": volunteer?.toJson(),
    };
}

List<ApiGetUser> apiGetUserFromJson(String str) => List<ApiGetUser>.from(json.decode(str).map((x) => ApiGetUser.fromJson(x)));

String apiGetUserToJson(List<ApiGetUser> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
ApiGetUser apiGetSingleUserFromJson(String str) => ApiGetUser.fromJson(json.decode(str));
String apiGetSingleUserToJson(ApiGetUser user) => json.encode(user);

// Format for getting users
class ApiGetUser {
  String? id;
  DateTime? creationDate;
  String? firstName;
  String? lastName;
  String? email;
  String? userName;
  String? dob;
  String? zip;
  String? state;
  String? country;
  int? userType;
  String? phoneNumber;
  int? idNumber;
  List<Event>? events;

  ApiGetUser({
    this.id,
    this.creationDate,
    this.firstName,
    this.lastName,
    this.email,
    this.userName,
    this.dob,
    this.zip,
    this.state,
    this.country,
    this.userType,
    this.phoneNumber,
    this.idNumber,
    this.events,
  });

  factory ApiGetUser.fromJson(Map<String, dynamic> json) => ApiGetUser(
    id: json["id"] as String?,
    creationDate: json["creationDate"] != null ? DateTime.parse(json["creationDate"]) : null,
    firstName: json["firstName"] as String?,
    lastName: json["lastName"] as String?,
    email: json["email"] as String?,
    userName: json["userName"] as String?,
    dob: json["dob"] as String?,
    zip: json["zip"] as String?,
    state: json["state"] as String?,
    country: json["country"] as String?,
    userType: json["userType"] as int?,
    phoneNumber: json["phoneNumber"] as String?,
    idNumber: json["idNumber"] as int?,
    events: json["events"] != null ? List<Event>.from(json["events"].map((x) => Event.fromJson(x))) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "creationDate": creationDate?.toIso8601String(),
    "firstName": firstName,
    "lastName": lastName,
    "email": email,
    "userName": userName,
    "dob": dob,
    "zip": zip,
    "state": state,
    "country": country,
    "userType": userType,
    "phoneNumber": phoneNumber,
    "idNumber": idNumber,
    "events": events != null ? List<dynamic>.from(events!.map((x) => x.toJson())) : null,
  };
}

//class for sending event data 
class EventDTO {
  int? id;
  String? name;
  String? street;
  String? city;
  String? zip;
  String? state;
  String? countryCode;
  String? startTime;
  String? endTime;
  String? date;
  String? eventLink;
  String? description;
  int? openSlots;
  int? host;
  List<InterestCategory>? interest;
  

  EventDTO({
      required this.id,
      required this.name,
      required this.street,
      required this.city,
      required this.zip,
      required this.state,
      required this.eventLink,
      required this.countryCode,
      required this.startTime,
      required this.endTime,
      required this.date,
      required this.openSlots,
      required this.host,
      required this.description,
      required this.interest
  });

  Map<String, dynamic> toJson() => {
      "id": id,
      "name": name,
      "street": street,
      "city": city,
      "zip": zip,
      "state": state,
      "eventURL": eventLink,
      "countryCode": countryCode,
      "startTime": startTime,
      "endTime": endTime,
      "date": date,
      "openSlots": openSlots,
      "host": host,
      "description": description,
      "interests": interest!.map((interest) => interest.index + 1).toList(),
  };
}


//class with all event data, for pulling from db 
class Event {
    int id;
    String name;
    String street;
    String city;
    String zip;
    String state;
    String countryCode;
    String startTime;
    String endTime;
    String date;
    String? eventLink;
    int openSlots;
    int host;
    String description;
    String hostNavigation;

    Event({
        required this.id,
        required this.name,
        required this.street,
        required this.city,
        required this.zip,
        required this.state,
        required this.countryCode,
        required this.startTime,
        required this.endTime,
        required this.date,
        required this.eventLink,
        required this.openSlots,
        required this.host,
        required this.description,
        required this.hostNavigation,
    });

    factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json["id"] ?? 1,
        name: json["name"] ?? "",
        street: json["street"] ?? "",
        city: json["city"] ?? "",
        zip: json["zip"] ?? "",
        state: json["state"] ?? "",
        countryCode: json["countryCode"] ?? "",
        startTime: json["startTime"] ?? "",
        endTime: json["endTime"] ?? "",
        date: json["date"] ?? "",
        eventLink: json["eventURL"] ?? '',
        openSlots: json["openSlots"] ?? 1,
        host: json["host"] ?? 1,
        hostNavigation: json["hostNavigation"] ?? "",
        description: json["description"] ?? "",
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "street": street,
        "city": city,
        "zip": zip,
        "state": state,
        "countryCode": countryCode,
        "startTime": startTime,
        "endTime": endTime,
        "date": date,
        "openSlots": openSlots,
        "host": host,
        "eventURL": eventLink,
        "description": description,
        "hostNavigation": hostNavigation,
    };
}

enum InterestCategory {
  none,
  environmentalConservation,
  communityService,
  educationTutoring,
  healthWellness,
  youthDevelopment,
  artsCulture,
  animalWelfare,
  disasterRelief,
  seniorServices,
  advocacySocialJustice,
  sportsRecreation,
}

const Map<int, InterestCategory> interestCategoryMap = {
  1: InterestCategory.none,
  2: InterestCategory.environmentalConservation,
  3: InterestCategory.communityService,
  4: InterestCategory.educationTutoring,
  5: InterestCategory.healthWellness,
  6: InterestCategory.youthDevelopment,
  7: InterestCategory.artsCulture,
  8: InterestCategory.animalWelfare,
  9: InterestCategory.disasterRelief,
  10: InterestCategory.seniorServices,
  11: InterestCategory.advocacySocialJustice,
  12: InterestCategory.sportsRecreation,
};

class Interest {
  int id;
  InterestCategory interests;
  List<Event>? events;

  Interest({
    required this.id,
    required this.interests,
    this.events,
  });

  // map the string to the corresponding InterestCategory enum
  static InterestCategory _mapStringToInterestCategory(String interestStr) {
    switch (interestStr) {
      case 'None':
        return InterestCategory.none;
      case 'Environmental_Conservation':
        return InterestCategory.environmentalConservation;
      case 'Community_Service':
        return InterestCategory.communityService;
      case 'Education_and_Tutoring':
        return InterestCategory.educationTutoring;
      case 'Health_and_Wellness':
        return InterestCategory.healthWellness;
      case 'Youth_Development':
        return InterestCategory.youthDevelopment;
      case 'Arts_and_Culture':
        return InterestCategory.artsCulture;
      case 'Animal_Welfare':
        return InterestCategory.animalWelfare;
      case 'Disaster_Relief':
        return InterestCategory.disasterRelief;
      case 'Senior_Services':
        return InterestCategory.seniorServices;
      case 'Advocacy_and_Social_Justice':
        return InterestCategory.advocacySocialJustice;
      case 'Sports_and_Recreation':
        return InterestCategory.sportsRecreation;
      default:
        return InterestCategory.none; // Default value if no match found
    }
  }

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id'],
      interests: _mapStringToInterestCategory(json['interests']),
      events: json['events'] != null
          ? List<Event>.from(json['events'].map((x) => Event.fromJson(x)))
          : null,
    );
  }

  // Convert Interest object back to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'interests': _interestCategoryToString(interests),
        'events': events != null ? List<dynamic>.from(events!.map((x) => x.toJson())) : null,
      };

  // Helper method to map InterestCategory to string
  static String _interestCategoryToString(InterestCategory interest) {
    switch (interest) {
      case InterestCategory.environmentalConservation:
        return 'Environmental_Conservation';
      case InterestCategory.communityService:
        return 'Community_Service';
      case InterestCategory.educationTutoring:
        return 'Education_and_Tutoring';
      case InterestCategory.healthWellness:
        return 'Health_and_Wellness';
      case InterestCategory.youthDevelopment:
        return 'Youth_Development';
      case InterestCategory.artsCulture:
        return 'Arts_and_Culture';
      case InterestCategory.disasterRelief:
        return 'Disaster_Relief';
      case InterestCategory.seniorServices:
        return 'Senior_Services';
      case InterestCategory.advocacySocialJustice:
        return 'Advocacy_and_Social_Justice';
      case InterestCategory.sportsRecreation:
        return 'Sports_and_Recreation';
      default:
        return 'Environmental_Conservation'; // Default value, TODO
    }
  }
}

List<ApiGetOrg> apiGetOrgFromJson(String str) => List<ApiGetOrg>.from(json.decode(str).map((x) => ApiGetOrg.fromJson(x)));
ApiGetOrg apiGetSingleOrgFromJson(String str) => ApiGetOrg.fromJson(json.decode(str));

class ApiGetOrg {
    int ? userId;
    String? ein;
    String ? website;
    String ? orgName;
    String ? phone;
    String ? zip;
    String ? street;
    String ? city;
    String ? state;
    String ? countryCode;
    int ? verifiedNpo;

    ApiGetOrg({
        required this.userId,
        required this.ein,
        required this.website,
        required this.orgName,
        required this.phone,
        required this.zip,
        required this.street,
        required this.city,
        required this.state,
        required this.countryCode,
        required this.verifiedNpo,
    });

    factory ApiGetOrg.fromJson(Map<String, dynamic> json) => ApiGetOrg(
        userId: json["userId"],
        ein: json["ein"],
        website: json["website"],
        orgName: json["orgName"],
        phone: json["phone"],
        zip: json["zip"],
        street: json["street"],
        city: json["city"],
        state: json["state"],
        countryCode: json["countryCode"],
        verifiedNpo: json["verifiedNpo"],
    );
}

class Organization {
    int userId;
    String ein;
    String website;
    String orgName;
    String phone;
    String zip;
    String street;
    String city;
    String state;
    String countryCode;
    int verifiedNpo;
    List<OrgContact> orgContacts;
    String user;

    Organization({
        required this.userId,
        required this.ein,
        required this.website,
        required this.orgName,
        required this.phone,
        required this.zip,
        required this.street,
        required this.city,
        required this.state,
        required this.countryCode,
        required this.verifiedNpo,
        required this.orgContacts,
        required this.user,
    });

    factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        userId: json["userId"],
        ein: json["ein"],
        website: json["website"],
        orgName: json["orgName"],
        phone: json["phone"],
        zip: json["zip"],
        street: json["street"],
        city: json["city"],
        state: json["state"],
        countryCode: json["countryCode"],
        verifiedNpo: json["verifiedNpo"],
        orgContacts: List<OrgContact>.from(json["orgContacts"].map((x) => OrgContact.fromJson(x))),
        user: json["user"],
    );

    Map<String, dynamic> toJson() => {
        "userId": userId,
        "ein": ein,
        "website": website,
        "orgName": orgName,
        "phone": phone,
        "zip": zip,
        "street": street,
        "city": city,
        "state": state,
        "countryCode": countryCode,
        "verifiedNpo": verifiedNpo,
        "orgContacts": List<dynamic>.from(orgContacts.map((x) => x.toJson())),
        "user": user,
    };
}

class OrgContact {
    int contactId;
    String firstName;
    String lastName;
    String email;
    String phone;
    int organization;
    String organizationNavigation;

    OrgContact({
        required this.contactId,
        required this.firstName,
        required this.lastName,
        required this.email,
        required this.phone,
        required this.organization,
        required this.organizationNavigation,
    });

    factory OrgContact.fromJson(Map<String, dynamic> json) => OrgContact(
        contactId: json["contactId"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        email: json["email"],
        phone: json["phone"],
        organization: json["organization"],
        organizationNavigation: json["organizationNavigation"],
    );

    Map<String, dynamic> toJson() => {
        "contactId": contactId,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "phone": phone,
        "organization": organization,
        "organizationNavigation": organizationNavigation,
    };
}

class Volunteer {
    int idVolunteers;
    String prefCntctMthd;
    int confirmedTime;
    int unconfirmedTime;
    String idVolunteersNavigation;
    List<VolunteerAvailability> volunteerAvailabilities;
    List<Interest> interests;

    Volunteer({
        required this.idVolunteers,
        required this.prefCntctMthd,
        required this.confirmedTime,
        required this.unconfirmedTime,
        required this.idVolunteersNavigation,
        required this.volunteerAvailabilities,
        required this.interests,
    });

    factory Volunteer.fromJson(Map<String, dynamic> json) => Volunteer(
        idVolunteers: json["idVolunteers"],
        prefCntctMthd: json["prefCntctMthd"],
        confirmedTime: json["confirmedTime"],
        unconfirmedTime: json["unconfirmedTime"],
        idVolunteersNavigation: json["idVolunteersNavigation"],
        volunteerAvailabilities: List<VolunteerAvailability>.from(json["volunteerAvailabilities"].map((x) => VolunteerAvailability.fromJson(x))),
        interests: List<Interest>.from(json["interests"].map((x) => Interest.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "idVolunteers": idVolunteers,
        "prefCntctMthd": prefCntctMthd,
        "confirmedTime": confirmedTime,
        "unconfirmedTime": unconfirmedTime,
        "idVolunteersNavigation": idVolunteersNavigation,
        "volunteerAvailabilities": List<dynamic>.from(volunteerAvailabilities.map((x) => x.toJson())),
        "interests": List<dynamic>.from(interests.map((x) => x.toJson())),
    };
}

List<VolunteerAvailability> availabiltiesFromJson(String str) => List<VolunteerAvailability>.from(json.decode(str).map((x) => VolunteerAvailability.fromJson(x)));

String availabilitiesToJson(List<VolunteerAvailability> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class VolunteerAvailability {
    int id;
    int dayOfWeek;
    String startTime;
    String endTime;
    int volunteer;

    VolunteerAvailability({
        required this.id,
        required this.dayOfWeek,
        required this.startTime,
        required this.endTime,
        required this.volunteer,
    });

    factory VolunteerAvailability.fromJson(Map<String, dynamic> json) => VolunteerAvailability(
        id: json["id"],
        dayOfWeek: json["dayOfWeek"],
        startTime: json["startTime"],
        endTime: json["endTime"],
        volunteer: json["volunteer"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "dayOfWeek": dayOfWeek,
        "startTime": startTime,
        "endTime": endTime,
        "volunteer": volunteer,
    };
}