import 'package:flutter/material.dart';

class ObservationTable extends StatelessWidget {
  final List<Map<String, dynamic>> rawValues;
  final String displayUnit;

  const ObservationTable({
    Key? key,
    required this.rawValues,
    required this.displayUnit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (rawValues.isEmpty) {
      return const Text('No Data Found');
    }

    // The stack contains both your table and the arrow indicator
    return Stack(
      alignment: Alignment.centerRight, // Align the arrow to the right
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(
                  color: Colors.black38,
                  width: 1,
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1.4),
                  1: FlexColumnWidth(1.6),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(3),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[300]),
                    children: [
                      const Padding(padding: EdgeInsets.all(8.0), child: Text('Value')),
                      const Padding(padding: EdgeInsets.all(8.0), child: Text('Date')),
                      const Padding(padding: EdgeInsets.all(8.0), child: Text('Units')),
                      const Padding(padding: EdgeInsets.all(8.0), child: Text('Notes')),
                    ],
                  ),
                  ...rawValues.map((observation) => TableRow(
                        children: [
                          Padding(padding: EdgeInsets.all(8.0), child: Text('${observation['raw_value']}')),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              '${observation['date']}',
                              softWrap: false, // Prevents text from wrapping
                            ),
                          ),
                          Padding(padding: EdgeInsets.all(8.0), child: Text(displayUnit)),
                          Padding(padding: EdgeInsets.all(8.0), child: Text(observation['notes'] ?? '')),
                          //Padding(
                          //  padding: EdgeInsets.all(8.0),
                          //  child: SingleChildScrollView(
                          //    scrollDirection: Axis.horizontal,
                          //    child: Text(observation['notes'] ?? ''),
                          //  ),
                          //),
                        ],
                      )),
                ],
              ),
            ),
          ),
        ),
        // Positioned container for the arrow indicator
        Positioned(
          right: 4, // Slightly away from the right edge of the screen
          child: Container(
            decoration: BoxDecoration(
              // Optional: Add a contrasting background with some padding if you need
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 24, // Larger size
              color: Colors.blue[900], // A color that stands out
            ),
          ),
        ),
      ],
    );
  }
}
