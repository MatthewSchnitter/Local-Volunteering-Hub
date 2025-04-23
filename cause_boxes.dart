import 'package:flutter/material.dart';

// ignore: must_be_immutable
class causesBox extends StatelessWidget {
  //const causesBox({Key? key});

  List causesList = [
    "Animals",
    "Poverty",
    "Food",
    "Water & Sanitation",
    "Health",
    "Education",
    "Equality",
    "Energy",
    "Arts and Culture",
    "Climate",
    "Conservation",
    "Peace & Justice",
    "Family",
    "Crisis",
    "Refugees",
    "Homeless",
    "Community Development",
    "Religious"
  ];

  causesBox({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.deepPurple[200],
      content: Builder(
        builder: (BuildContext context) {
          return SizedBox(
            width: double.maxFinite,
            height: 450,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    2, // You can adjust the number of columns as needed
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: causesList.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  //color: Colors.white,
                  // Example background color
                  alignment: Alignment.center,
                  child: Text(causesList[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

