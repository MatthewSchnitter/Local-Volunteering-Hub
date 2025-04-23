// To parse this JSON data, do
//
//     final apiInterest = apiInterestFromJson(jsonString);

import 'dart:convert';

List<ApiInterest> apiInterestFromJson(String str) => List<ApiInterest>.from(json.decode(str).map((x) => ApiInterest.fromJson(x)));

String apiInterestToJson(List<ApiInterest> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ApiInterest {
    int idInterests;
    String interest1;
    List<Event> events;
    List<Volunteer> volunteers;

    ApiInterest({
        required this.idInterests,
        required this.interest1,
        required this.events,
        required this.volunteers,
    });

    factory ApiInterest.fromJson(Map<String, dynamic> json) => ApiInterest(
        idInterests: json["idInterests"],
        interest1: json["interest1"],
        events: List<Event>.from(json["events"].map((x) => Event.fromJson(x))),
        volunteers: List<Volunteer>.from(json["volunteers"].map((x) => Volunteer.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "idInterests": idInterests,
        "interest1": interest1,
        "events": List<dynamic>.from(events.map((x) => x.toJson())),
        "volunteers": List<dynamic>.from(volunteers.map((x) => x.toJson())),
    };
}

class Event {
    int eventId;
    String name;
    String street;
    String city;
    String zip;
    String state;
    String countryCode;
    String startTime;
    String endTime;
    String date;
    int openSlots;
    int host;
    Navigation hostNavigation;
    List<String> eventInterest1S;

    Event({
        required this.eventId,
        required this.name,
        required this.street,
        required this.city,
        required this.zip,
        required this.state,
        required this.countryCode,
        required this.startTime,
        required this.endTime,
        required this.date,
        required this.openSlots,
        required this.host,
        required this.hostNavigation,
        required this.eventInterest1S,
    });

    factory Event.fromJson(Map<String, dynamic> json) => Event(
        eventId: json["eventId"],
        name: json["name"],
        street: json["street"],
        city: json["city"],
        zip: json["zip"],
        state: json["state"],
        countryCode: json["countryCode"],
        startTime: json["startTime"],
        endTime: json["endTime"],
        date: json["date"],
        openSlots: json["openSlots"],
        host: json["host"],
        hostNavigation: Navigation.fromJson(json["hostNavigation"]),
        eventInterest1S: List<String>.from(json["eventInterest1s"].map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "eventId": eventId,
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
        "hostNavigation": hostNavigation.toJson(),
        "eventInterest1s": List<dynamic>.from(eventInterest1S.map((x) => x)),
    };
}

class Navigation {
    int idUsers;
    String chosenId;
    DateTime creationDate;
    String firstName;
    String lastName;
    String dob;
    String zip;
    String state;
    String phone;
    String email;
    String country;
    int userType;
    List<String> events;
    Organization organization;
    String volunteer;

    Navigation({
        required this.idUsers,
        required this.chosenId,
        required this.creationDate,
        required this.firstName,
        required this.lastName,
        required this.dob,
        required this.zip,
        required this.state,
        required this.phone,
        required this.email,
        required this.country,
        required this.userType,
        required this.events,
        required this.organization,
        required this.volunteer,
    });

    factory Navigation.fromJson(Map<String, dynamic> json) => Navigation(
        idUsers: json["idUsers"],
        chosenId: json["chosenId"],
        creationDate: DateTime.parse(json["creationDate"]),
        firstName: json["firstName"],
        lastName: json["lastName"],
        dob: json["dob"],
        zip: json["zip"],
        state: json["state"],
        phone: json["phone"],
        email: json["email"],
        country: json["country"],
        userType: json["userType"],
        events: List<String>.from(json["events"].map((x) => x)),
        organization: Organization.fromJson(json["organization"]),
        volunteer: json["volunteer"],
    );

    Map<String, dynamic> toJson() => {
        "idUsers": idUsers,
        "chosenId": chosenId,
        "creationDate": creationDate.toIso8601String(),
        "firstName": firstName,
        "lastName": lastName,
        "dob": dob,
        "zip": zip,
        "state": state,
        "phone": phone,
        "email": email,
        "country": country,
        "userType": userType,
        "events": List<dynamic>.from(events.map((x) => x)),
        "organization": organization.toJson(),
        "volunteer": volunteer,
    };
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
    Navigation idVolunteersNavigation;
    List<VolunteerAvailability> volunteerAvailabilities;
    List<String> interests;

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
        idVolunteersNavigation: Navigation.fromJson(json["idVolunteersNavigation"]),
        volunteerAvailabilities: List<VolunteerAvailability>.from(json["volunteerAvailabilities"].map((x) => VolunteerAvailability.fromJson(x))),
        interests: List<String>.from(json["interests"].map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "idVolunteers": idVolunteers,
        "prefCntctMthd": prefCntctMthd,
        "confirmedTime": confirmedTime,
        "unconfirmedTime": unconfirmedTime,
        "idVolunteersNavigation": idVolunteersNavigation.toJson(),
        "volunteerAvailabilities": List<dynamic>.from(volunteerAvailabilities.map((x) => x.toJson())),
        "interests": List<dynamic>.from(interests.map((x) => x)),
    };
}

class VolunteerAvailability {
    int availableId;
    int dayOfWeek;
    String startTime;
    String endTime;
    int volunteer;
    String volunteerNavigation;

    VolunteerAvailability({
        required this.availableId,
        required this.dayOfWeek,
        required this.startTime,
        required this.endTime,
        required this.volunteer,
        required this.volunteerNavigation,
    });

    factory VolunteerAvailability.fromJson(Map<String, dynamic> json) => VolunteerAvailability(
        availableId: json["availableId"],
        dayOfWeek: json["dayOfWeek"],
        startTime: json["startTime"],
        endTime: json["endTime"],
        volunteer: json["volunteer"],
        volunteerNavigation: json["volunteerNavigation"],
    );

    Map<String, dynamic> toJson() => {
        "availableId": availableId,
        "dayOfWeek": dayOfWeek,
        "startTime": startTime,
        "endTime": endTime,
        "volunteer": volunteer,
        "volunteerNavigation": volunteerNavigation,
    };
}
