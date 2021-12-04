// ignore_for_file: file_names, prefer_const_literals_to_create_immutables
import 'dart:convert';

import 'package:data_logger_app/src/models/FileRecord.dart';
import 'package:data_logger_app/src/services/GeoLocatorService.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:data_logger_app/src/services/publicHolidayService.dart';
import 'package:data_logger_app/src/services/timeService.dart';
import 'package:data_logger_app/src/services/fileService.dart';
import 'package:google_sign_in/google_sign_in.dart' as signIn;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:data_logger_app/src/services/googleAuthClientService.dart';

class TestGeolocatorScreen extends StatefulWidget {
  const TestGeolocatorScreen({ Key? key }) : super(key: key);

  @override
  _TestGeolocatorScreenState createState() => _TestGeolocatorScreenState();
}

class _TestGeolocatorScreenState extends State<TestGeolocatorScreen> {

  // property area--------------------------------------------------------------
  String lat = "";
  String long =  "";
  String timeStamp = "";
  String currentDate = "";

  GeolocatorService geolocatorService = GeolocatorService();
  PublicHolidayService  publicHolidayService = PublicHolidayService(api_key: "04195d83220a781fec0ef7811aab0c1c3182b435",country: "LK",year: "2021");

  final googleSignIn = signIn.GoogleSignIn.standard(
                scopes: [drive.DriveApi.driveScope]
              );

  FileService fileService = FileService(fileName: "Test.json");

  // Tempory button controls------------
  bool isFileCreated = false;
  bool isUploadToDrive = false;
  bool isFileCleaned = false;

  

  @override
  Widget build(BuildContext context) {
     //Position position = await geoService.getCurrentPosition();

    return Scaffold(
      appBar: AppBar(
        title: Text("Test Geolocation Module"),
      ),
       body: Column(
         children: <Widget> [

          const SizedBox(height: 50,),
          Center(child: Text("Lat : $lat - Long : $long"),),
          const SizedBox(height: 50,),
          Center(child: Text(" Timestamp : $timeStamp"),),
          const SizedBox(height: 50,),
          ElevatedButton(
            onPressed: !isUploadToDrive ? ()async{

              Position currentPosition = await geolocatorService.getCurrentPosition();

              await publicHolidayService.getPublicHolidayData(); // initially at the test stage. this should run only once in the day

              await fileService.setLocalFile();
              await fileService.checkFileEmpty();

              FileRecord record ;

              setState((){
                isFileCreated = true;

                lat = currentPosition.latitude.toString();
                long = currentPosition.longitude.toString();
                
    
                TimeService timeService = TimeService();
                timeStamp = timeService.getTimeStamp();
                currentDate = timeService.getCurrentDate();

                bool isHoilday = publicHolidayService.checkIsHoliday(timeService.getCurrentDate());
                bool isRushHour = timeService.checkIsRushHour();
                bool isWeekend  = timeService.checkIsWeekend();

                record= FileRecord(
                  longitude: long, 
                  latitude: lat, 
                  timeStamp: timeStamp,
                  isRushHour: isRushHour, 
                  isWeekend: isWeekend,
                  isPublicHoliday: isHoilday
                );

                print(record.toJson());

                
                fileService.writeContent(jsonEncode(record.toJson()));
              });
              print("Test file read start---------------->\n");
              print(await fileService.readFile());
              
            } : null, 
            child:const Text("Get Current Location")
            ),
            const SizedBox(height: 50,),
            ElevatedButton(
              onPressed: isFileCreated ? ()async{
                setState((){
                  isUploadToDrive = true;
                  isFileCreated = false;
                });

                final account = await googleSignIn.signIn();
                print("Sign in to account : $account");

                // initialize driveApi
                final authHeaders = await account!.authHeaders;
                final authenticateClient = GoogleAuthClientService(authHeaders);
                final driveApi = drive.DriveApi(authenticateClient);


                await fileService.fileFormatToJSON();
                print("File read start after format to JSON ---------------->\n");
                print(await fileService.readFile());

                drive.File file = drive.File();
                
                try {
                  file.name = "DataLoggerRecords_$timeStamp.json";
                  drive.File response = await driveApi.files.create(file,uploadMedia: drive.Media(
                    fileService.getFile().openRead(),
                    fileService.getFile().lengthSync(),
                  ));

                  print("Succuessfully uploaded the file with the size : ${response.size}");
                }
                catch(e){
                  print("Dirve file upload exeption occurs : $e");
                }
                finally{
                  authenticateClient.close();
                }

              }: null, 
              child:const Text("Upload file to Drive")
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: isUploadToDrive ? ()async{
                  
                  // This part was added temporary
                  fileService.clearFile();
                  print("File after clean :");
                  print(await fileService.readFile());

                  setState((){
                    isUploadToDrive = false;
                  });
                  
                }:null,     
                child:const Text("Clear File")
                )
         ],
       ),
    );
  }
}