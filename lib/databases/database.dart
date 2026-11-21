import 'package:cloud_firestore/cloud_firestore.dart';

//  NOTEBOOK class
class Notebook {
    final String id;
    final String name;
    final String color; // e.g., '#FF5733' or 'red' like the builtin Colors.red
    final DateTime dateCreated;
    final DateTime dateModified;

    //  constructor
    Notebook({
        required this.id,
        required this.name,
        required this.color,
        required this.dateCreated,
        required this.dateModified,
    });

    //  toMap method
    //  get Dart object -> turn into Map -> save into FireBase
    Map<String, dynamic> toMap() {
        //  returns a dictionary/map
        return
        {
            'name': name,
            'color': color,
            'dateCreated': Timestamp.fromDate(dateCreated),
            'dateModified': Timestamp.fromDate(dateModified),
        };
    }

    //  fromMap method
    //  get FireBase map + doc.Id -> turn into Dart object
    factory Notebook.fromMap(Map<String, dynamic>map,String docId) {
        return Notebook(
        id: docId,
        name: map['name'] ?? 'Untitled Notebook',
        color: map['color'] ?? '#2196F3',
        dateCreated: (map['dateCreated'] as Timestamp?)?.toDate() ?? DateTime.now(),
        dateModified: (map['dateModified'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
    }
}