// To parse this JSON data, do
//
//     final apiOrganization = apiOrganizationFromJson(jsonString);

import 'dart:convert';

List<ApiOrganization> apiOrganizationFromJson(String str) => List<ApiOrganization>.from(json.decode(str).map((x) => ApiOrganization.fromJson(x)));

String apiOrganizationToJson(List<ApiOrganization> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ApiOrganization {
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
    User user;

    ApiOrganization({
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

    factory ApiOrganization.fromJson(Map<String, dynamic> json) => ApiOrganization(
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
        user: User.fromJson(json["user"]),
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
        "user": user.toJson(),
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

class User {
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
    List<Event> events;
    String organization;
    Volunteer volunteer;

    User({
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

    factory User.fromJson(Map<String, dynamic> json) => User(
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
        events: List<Event>.from(json["events"].map((x) => Event.fromJson(x))),
        organization: json["organization"],
        volunteer: Volunteer.fromJson(json["volunteer"]),
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
        "events": List<dynamic>.from(events.map((x) => x.toJson())),
        "organization": organization,
        "volunteer": volunteer.toJson(),
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
    String hostNavigation;
    List<Interest> eventInterest1S;

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
        hostNavigation: json["hostNavigation"],
        eventInterest1S: List<Interest>.from(json["eventInterest1s"].map((x) => Interest.fromJson(x))),
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
        "hostNavigation": hostNavigation,
        "eventInterest1s": List<dynamic>.from(eventInterest1S.map((x) => x.toJson())),
    };
}

class Interest {
    int idInterests;
    String interest1;
    List<String> events;
    List<String> volunteers;

    Interest({
        required this.idInterests,
        required this.interest1,
        required this.events,
        required this.volunteers,
    });

    factory Interest.fromJson(Map<String, dynamic> json) => Interest(
        idInterests: json["idInterests"],
        interest1: json["interest1"],
        events: List<String>.from(json["events"].map((x) => x)),
        volunteers: List<String>.from(json["volunteers"].map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "idInterests": idInterests,
        "interest1": interest1,
        "events": List<dynamic>.from(events.map((x) => x)),
        "volunteers": List<dynamic>.from(volunteers.map((x) => x)),
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
