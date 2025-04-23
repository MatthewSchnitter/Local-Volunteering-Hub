import 'package:flutter/material.dart';
import 'user.dart';  


class EventProvider with ChangeNotifier {
  List<Event> userEvents = [];
  List<Event> favoriteEvents = [];
  List<Event> regEvents = [];
  List<Event> recEvents = [];

  bool hasFetchedEvents = false; // Flag to track whether events have been loaded initially

  // Function to set events globally
  void setUserEvents(List<Event> events) {
    userEvents = events;
    notifyListeners();
  }

  void setFavoriteEvents(List<Event> events) {
    favoriteEvents = events;
    notifyListeners();
  }

  void setRegisteredEvents(List<Event> events) {
    regEvents = events;
    notifyListeners();
  }

  void setRecommendedEvents(List<Event> events) {
    recEvents = events;
    notifyListeners();
  }

  // Function to check if events have been fetched
  bool get eventsFetched => hasFetchedEvents;

  // Function to update the flag indicating that events have been fetched
  void markEventsAsFetched() {
    hasFetchedEvents = true;
    notifyListeners();
  }

  // Function to clear events
  void clearEvents() {
    userEvents = [];
    favoriteEvents = [];
    regEvents = [];
    recEvents = [];
    notifyListeners();
  }
}