import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:learning_app/model/shape_model.dart';
import 'package:learning_app/services/database_service.dart';


class DisplayShapes extends StatefulWidget {
  const DisplayShapes({super.key});

  @override
  State<DisplayShapes> createState() => _DisplayShapesState();
}

class _DisplayShapesState extends State<DisplayShapes> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Objects',
            style: TextStyle(fontSize: screenWidth * 0.05)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<List<ShapeModel>>(
          stream: _databaseService.shapes,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<ShapeModel> shapes = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shapes.length,
                itemBuilder: (context, index) {
                  final shape = shapes[index];
                  final DateTime dt = shape.timestamp.toDate();
                  return SizedBox(
                    width: screenWidth * 0.9,
                    height: screenHeight * 0.15,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Card(
                        margin: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.010),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        color: Colors.grey[300],
                        child: Slidable(
                          startActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            children: [
                              SlidableAction(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: 'Edit',
                                onPressed: (context) {
                                  _showAddShapeDialog(context, shape: shape);
                                },
                              ),
                              SlidableAction(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                                onPressed: (context) async {
                                  await _databaseService.deleteShape(
                                      shape.shapeId, shape.imageUrl);
                                },
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(screenWidth * 0.03),
                            child: ListTile(
                              leading: shape.imageUrl.isNotEmpty
                                  ? Image.network(
                                      shape.imageUrl,
                                      width: screenWidth * 0.18,
                                      height: screenHeight * 0.1,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: screenWidth * 0.18,
                                      height: screenHeight * 0.1,
                                      color: Colors.grey,
                                    ),
                              title: Text(
                                shape.shapeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Text(
                                '${dt.day}/${dt.month}/${dt.year}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.deepPurple,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _showAddShapeDialog(BuildContext context, {ShapeModel? shape}) {
    final TextEditingController _shapeNameController =
        TextEditingController(text: shape?.shapeName);
    final TextEditingController _imageUrlController =
        TextEditingController(text: shape?.imageUrl);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detected Shape'),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  TextField(
                    controller: _shapeNameController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (shape != null) {
                  await _databaseService.updateShape(
                    shape.shapeId,
                    _shapeNameController.text,
                  );
                } else {
                  await _databaseService.saveShape(
                    _shapeNameController.text,
                    _imageUrlController.text,
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
