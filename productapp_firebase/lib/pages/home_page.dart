import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:productapp_firebase/services/firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService();

  // Text editing controllers for form fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  String? selectedProductID;

  bool isCreateEnabled = true;
  bool isUpdateEnabled = false;
  bool isDeleteEnabled = false;

  // Clears the form fields and resets button states
  void clearFields() {
    nameController.clear();
    descriptionController.clear();
    priceController.clear();
    selectedProductID = null;
    setState(() {
      isCreateEnabled = true;
      isUpdateEnabled = false;
      isDeleteEnabled = false;
    });
  }

  // Show alert dialog for error messages
  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show confirmation dialog for actions like deletion
  Future<bool> _showConfirmationDialog(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Creates a new product in Firestore
  void _createProduct() {
    if (nameController.text.isEmpty || descriptionController.text.isEmpty || priceController.text.isEmpty) {
      _showAlertDialog('Please fill in all fields');
    } else {
      try {
        double price = double.parse(priceController.text);
        firestoreService.addProduct(
          nameController.text,
          descriptionController.text,
          price,
        );
        clearFields();
      } catch (e) {
        _showAlertDialog('Please enter a valid price');
      }
    }
  }

  // Updates the selected product in Firestore
  void _updateProduct() {
    if (selectedProductID != null) {
      if (nameController.text.isEmpty || descriptionController.text.isEmpty || priceController.text.isEmpty) {
        _showAlertDialog('Please fill in all fields');
      } else {
        try {
          double price = double.parse(priceController.text);
          firestoreService.updateProduct(
            selectedProductID!,
            nameController.text,
            descriptionController.text,
            price,
          );
          clearFields();
        } catch (e) {
          _showAlertDialog('Please enter a valid price');
        }
      }
    }
  }

  // Deletes the selected product from Firestore
  void _deleteProduct() async {
    if (selectedProductID != null) {
      bool confirmed = await _showConfirmationDialog('Do you confirm the deletion?');
      if (confirmed) {
        firestoreService.deleteProduct(selectedProductID!);
        clearFields();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Soft Drinks",
          style: TextStyle(fontFamily: 'CustomFont', color: Colors.white, fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: Colors.black87,
        toolbarHeight: 60,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form fields for product input
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Price(Rs)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            // Buttons for create, update, delete, and clear
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isCreateEnabled ? _createProduct : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Create", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: isUpdateEnabled ? _updateProduct : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                  child: const Text("Update", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: isDeleteEnabled ? _deleteProduct : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Delete", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: clearFields,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Displaying products in a DataTable
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestoreService.getNotesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var notesList = snapshot.data!.docs;
                    return DataTable(
                      columnSpacing: 20.0,
                      columns: const [
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Description")),
                        DataColumn(label: Text("Price")),
                        DataColumn(label: Text("Actions")),
                      ],
                      rows: notesList.map((document) {
                        var data = document.data() as Map<String, dynamic>;
                        return DataRow(cells: [
                          DataCell(
                            Flexible(child: Text(data['name'])),
                          ),
                          DataCell(
                            Flexible(child: Text(data['description'])),
                          ),
                          DataCell(
                            Flexible(child: Text(data['price'].toString())),
                          ),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () {
                                  setState(() {
                                    selectedProductID = document.id;
                                    nameController.text = data['name'];
                                    descriptionController.text = data['description'];
                                    priceController.text = data['price'].toString();
                                    isCreateEnabled = false;
                                    isUpdateEnabled = true;
                                    isDeleteEnabled = true;
                                  });
                                },
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    );
                  } else {
                    return const Center(child: Text("No products found"));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
