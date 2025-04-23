// class APIEvent {
//   final int EventId;
//   final String Name;
//   final String City;
//   final String Zip;
//   final String State;
//   final String CountryCode;
//   final String StartTime;
//   final String EndTime;
//   final String Date;
//   final int OpenSlots;
//   final int Host;

//   APIEvent(this.EventId, this.Name, this.City, this.Zip, this.State, this.CountryCode, this.StartTime, this.EndTime, this.Date, this.OpenSlots, this.Host,);

//   APIEvent.fromJson(Map<String, dynamic> json): 
//     EventId = json["eventID"] as int,
//     Name = json['name'] as String,
//     City = json['city'] as String,
//     Zip = json['zip'] as String,
//     State = json['state'] as String,
//     CountryCode = json['country code'] as String,
//     StartTime = json['start time'] as String,
//     EndTime = json['end time'] as String,
//     Date = json['date'] as String,
//     OpenSlots = json['open slots'] as int,
//     Host = json['host'] as int;
// }

// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

List<APIEvent> welcomeFromJson(String str) => List<APIEvent>.from(json.decode(str).map((x) => APIEvent.fromJson(x)));

String welcomeToJson(List<APIEvent> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class APIEvent {
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

    APIEvent({
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
    });

    factory APIEvent.fromJson(Map<String, dynamic> json) => APIEvent(
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
    };
}

class Event {
  final String title;
  Event(this.title);
}

