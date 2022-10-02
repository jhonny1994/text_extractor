import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:text_extractor/apikey.dart';

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  String? base64Image;
  XFile? image;
  String? resultText;
  bool isLoading = false;

  void getImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        image = pickedImage;
      });
    }

    final bytes = File(pickedImage!.path).readAsBytesSync();

    setState(() {
      base64Image = "data:image/png;base64,${base64Encode(bytes)}";
    });
  }

  void getText(String image) async {
    setState(() {
      isLoading = !isLoading;
    });
    var dio = Dio();
    var url = 'https://api.ocr.space/Parse/Image';
    var formData = FormData.fromMap({
      'language': 'eng',
      'isOverlayRequired': true,
      'apikey': apiKey,
      'base64image': image,
    });

    Response response = await dio.post(
      url,
      data: formData,
    );

    setState(() {
      resultText = response.data['ParsedResults'][0]['ParsedText'];
      isLoading = !isLoading;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafd),
      floatingActionButton: image == null
          ? FloatingActionButton(
              onPressed: getImage,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: image == null
                ? Text(
                    'Select an image to start.',
                    style: Theme.of(context).textTheme.headline5,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Input image',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        height: MediaQuery.of(context).size.height * 0.5,
                        width: double.infinity,
                        child: Image.file(File(image!.path)),
                      ),
                      Text(
                        'Output text',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        color: Colors.grey.shade200,
                        height: MediaQuery.of(context).size.height * 0.25,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : resultText == null
                                      ? Container()
                                      : InkWell(
                                          onTap: () =>
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                            duration: Duration(seconds: 1),
                                            behavior: SnackBarBehavior.floating,
                                            content: Text(
                                                "Text copied to clipboard"),
                                          )),
                                          child: SizedBox(
                                            height: double.infinity,
                                            width: double.infinity,
                                            child: Text(
                                              resultText!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ),
                                        ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () {
                                  getText(base64Image!);
                                },
                                child: const Text('Get text')),
                            const SizedBox(width: 10),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    image = null;
                                    base64Image = null;
                                    resultText = null;
                                  });
                                },
                                child: const Text(
                                  'clear',
                                ))
                          ]),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
