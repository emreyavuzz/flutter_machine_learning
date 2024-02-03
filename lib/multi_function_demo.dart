import 'dart:io';
import 'package:DetectApp/second_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';

class MultiFunctionDemo extends StatefulWidget {
  @override
  _MultiFunctionDemoState createState() => _MultiFunctionDemoState();
}

class _MultiFunctionDemoState extends State<MultiFunctionDemo> {
  File? _cameraImage;
  File? _galleryImage;
  final picker = ImagePicker();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<dynamic> _recognitions = [];
  var v = "";
  bool showPredictions = false;

  @override
  void initState() {
    super.initState();
    loadModel().then((value) {
      setState(() {});
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/hayvan.tflite",
      labels: "assets/labelmap.txt",
    );
  }

  @override
  void dispose() {
    // TensorFlow Lite modelini kapatma
    Tflite.close();

    // Recognitions listesini temizleme
    _recognitions.clear();

    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _cameraImage = File(pickedFile.path);
        _galleryImage = null;
        showPredictions = false;
        _recognitions = [];
      } else {
        print('Fotoğraf Seçilmedi.');
      }
    });

    if (_cameraImage != null) {
      _detectImage(_cameraImage!, _recognitions);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _galleryImage = File(pickedFile.path);
        _cameraImage = null;
        showPredictions = false;
        _recognitions = [];
      } else {
        print('Fotoğraf Seçilmedi.');
      }
    });

    if (_galleryImage != null) {
      _detectImage(_galleryImage!, _recognitions);
    }
  }

  Future<void> _detectImage(File image, List<dynamic> recognitions) async {
    int startTime = DateTime.now().millisecondsSinceEpoch;
    recognitions.clear(); // Temizleme işlemi eklendi
    var newRecognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    List<String> labels = newRecognitions
            ?.map<String>((recognition) => recognition['label'].toString())
            .toList() ??
        [];

    setState(() {
      recognitions.addAll(newRecognitions!);
      v = labels.join(', ');
      print(recognitions);
    });

    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/v904-nunny-010-e.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_cameraImage != null || _galleryImage != null)
                Image.file(
                  _cameraImage ?? _galleryImage!,
                  height: 180,
                  width: 180,
                )
              else
                const Text('Fotoğraf Seçilmedi.'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera),
                label: const Text('Kamera Çek'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo),
                label: const Text('Galeri Seç'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                  onPrimary: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    showPredictions = !showPredictions;
                  });
                  if (showPredictions) {
                    if (_cameraImage != null) {
                      _detectImage(_cameraImage!, _recognitions);
                    } else if (_galleryImage != null) {
                      _detectImage(_galleryImage!, _recognitions);
                    }
                  }
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Tahminleri Göster/Gizle'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.purple,
                  onPrimary: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // İkinci sayfaya gitmeden önce _recognitions listesini sıfırla
                  _recognitions.clear();

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SecondPage()),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Cinsiyet Tahmin Et'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.green,
                  onPrimary: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              if (showPredictions && _recognitions.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  padding: const EdgeInsets.all(9),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tahminler:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      for (var recognition in _recognitions)
                        Text(
                          '- ${recognition['label']} : ${(recognition['confidence'] * 100).toStringAsFixed(2)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(),
            ],
          ),
        ),
      ),
    );
  }
}
