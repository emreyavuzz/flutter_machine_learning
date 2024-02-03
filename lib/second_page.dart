import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';

class SecondPage extends StatefulWidget {
  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  File? _cameraImage;
  File? _galleryImage;
  final picker = ImagePicker();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<dynamic> _secondPageRecognitions = [];
  var _secondPageV = "";
  bool _secondPageShowPredictions = false;

  @override
  void initState() {
    super.initState();
    loadModel().then((value) {
      setState(() {});
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/cinsiyet.tflite",
      labels: "assets/labels.txt",
    );
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _cameraImage = File(pickedFile.path);
        _galleryImage = null;
        _secondPageShowPredictions = false;
        _secondPageRecognitions = [];
      } else {
        print('Fotoğraf Seçilmedi.');
      }
    });

    if (_cameraImage != null) {
      _detectImage(_cameraImage!, _secondPageRecognitions);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _galleryImage = File(pickedFile.path);
        _cameraImage = null;
        _secondPageShowPredictions = false;
        _secondPageRecognitions = [];
      } else {
        print('Fotoğraf Seçilmedi.');
      }
    });

    if (_galleryImage != null) {
      _detectImage(_galleryImage!, _secondPageRecognitions);
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
      _secondPageV = labels.join(', ');
      print(recognitions);
      _secondPageShowPredictions =
          recognitions != null && recognitions.isNotEmpty;
    });

    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Cinsiyet Tahmin Etme'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
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
                    _secondPageShowPredictions = !_secondPageShowPredictions;
                  });
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
              if (_secondPageShowPredictions &&
                  _secondPageRecognitions.isNotEmpty)
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
                      for (var recognition in _secondPageRecognitions)
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
