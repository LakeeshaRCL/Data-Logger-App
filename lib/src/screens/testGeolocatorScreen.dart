// ignore_for_file: file_names, prefer_const_literals_to_create_immutables, unnecessary_null_comparison
import 'dart:convert';
import 'package:data_logger_app/src/models/FileRecord.dart';
import 'package:data_logger_app/src/services/GeoLocatorService.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:data_logger_app/src/services/publicHolidayService.dart';
import 'package:data_logger_app/src/services/timeService.dart';
import 'package:data_logger_app/src/services/fileService.dart';
import 'package:google_sign_in/google_sign_in.dart' as signIn;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:data_logger_app/src/services/googleAuthClientService.dart';
import 'package:logger/logger.dart';

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

  late var account; // A property to store current sign in google account

  GeolocatorService geolocatorService = GeolocatorService();
  PublicHolidayService  publicHolidayService = PublicHolidayService(api_key: "04195d83220a781fec0ef7811aab0c1c3182b435",country: "LK",year: "2021");

  final googleSignIn = signIn.GoogleSignIn.standard(
                scopes: [drive.DriveApi.driveScope]
              );


  FileService fileService = FileService(fileName:"Logged_data_${getDateFromTimeStamp(DateTime.now().toString())}.json");

  Logger logger = Logger();

// Button controllers======================================================================================
  bool startBtnTapped = false; // property check is start button was tapped
  bool stopBtnTapped = false;
  bool isUserAccountAvailable = false; // property to check is sign in user account available currently

  late bool isLogging; // a property to control the datalogging period


  @override
  void initState() {
    super.initState();
    isLogging = true;
    logger.d("InitState() called - isLogging : $isLogging");

    // This fucntionality needed to be verified in a actual app
    // Used to check is logged user is available
    googleSignIn.onCurrentUserChanged.listen((signIn.GoogleSignInAccount? currentAccount ) {
      setState(() {
        account = currentAccount;
        logger.i("initState account : ${account.toString()}");
        if(account != null){
          isUserAccountAvailable = true;
        }
        
      });
    });
     googleSignIn.signInSilently();
  }

  @override
  Widget build(BuildContext context) {

     //Position position = await geoService.getCurrentPosition();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Logger"),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            onPressed: !isUserAccountAvailable ? ()async{
              account = await googleSignIn.signIn();
              logger.i("Sign in to account : $account");
            } : null, 
            icon: Icon(Icons.cloud))
        ],
      ),
       body: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: <Widget> [
          Center(
            child: ElevatedButton( // Start button
              onPressed: !startBtnTapped ? ()async{
                setState(() {
                  startBtnTapped = true;
                });

                await publicHolidayService.getPublicHolidayData(); // initially at the test stage. this should run only once in the day

                await fileService.setLocalFile(); // set local file

                fileService.clearFile(); // add because of while loop continuously appending the data. Before start the logging clear the file.

                int recordDuration = 6; // Stores the record duration in seconds.  (this should -4 from actual delay due to other delays)
                
                while(isLogging){
        
                  await fileService.checkFileEmpty();  
                  Position currentPosition = await geolocatorService.getCurrentPosition(); 
                  logData(currentPosition);

                  String nextRecord = getDateTimeUpToSeconds(DateTime.now().add( Duration(seconds: recordDuration)).toString());
                  logger.w("Next : $nextRecord");

                  await Future.delayed(Duration(seconds: recordDuration));
 
                }
                
                logger.w("Data Logging ends - isLogging : $isLogging");
                await readFile();
                await uploadToDrive(account);

                setState(() {
                  isLogging = true;
                });

                logger.i("Data logging back to start state - isLogging : $isLogging");

              } : null,

              style: ElevatedButton.styleFrom(
                fixedSize: const Size(250, 150),
                primary: Colors.green
              ),

              child:const Text(
                "Start",
                style: TextStyle(fontSize:30),
              )
            ),
          ),
          const SizedBox(height:200,),
          ElevatedButton( // Stop button
            onPressed: startBtnTapped ? (){
              setState(() {
                isLogging = false;
                logger.w("Stop button was tapped");
                startBtnTapped = false;
              });
            } : null, 

            child: const Text(
              "Stop",
              style: TextStyle(
                color: Colors.black,
                fontSize: 25,
              ),),
            style: ElevatedButton.styleFrom(
              primary: Colors.amber,
              fixedSize: const Size(250, 50)
            ),
          ),
         ],
       ),
    );
  }


  /*
   * ==============================================================
   * A method to execute data logging task
   */
  void logData(Position currentPosition) {

    lat = currentPosition.latitude.toString();
    long = currentPosition.longitude.toString();
    

    TimeService timeService = TimeService();
    timeStamp = timeService.getTimeStamp();
    currentDate = timeService.getCurrentDate();

    bool isHoilday = publicHolidayService.checkIsHoliday(timeService.getCurrentDate());
    bool isRushHour = timeService.checkIsRushHour();
    bool isWeekend  = timeService.checkIsWeekend();

    FileRecord record= FileRecord(
      longitude: long, 
      latitude: lat, 
      timeStamp: timeStamp,
      isRushHour: isRushHour, 
      isWeekend: isWeekend,
      isPublicHoliday: isHoilday
    );

    logger.i(record.toJson());
    fileService.writeContent(jsonEncode(record.toJson()));
  }



  /*
   * ================================================================
   * Method to upload logged data into goolge drive 
   */
  Future<void> uploadToDrive(var account)async{

    // final account = await googleSignIn.signIn();
    print("Current Google Account : $account");

    // initialize driveApi
    final authHeaders = await account!.authHeaders;
    final authenticateClient = GoogleAuthClientService(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);


    await fileService.fileFormatToJSON();
    print("File read start after format to JSON ---------------->\n");
    print(await fileService.readFile());

    drive.File file = drive.File();
    
    try {
      file.name = "DataLoggerRecord_$timeStamp.json";
      drive.File response = await driveApi.files.create(file,uploadMedia: drive.Media(
        fileService.getFile().openRead(),
        fileService.getFile().lengthSync(),
      ));

      logger.i("Succuessfully uploaded the file with the size : ${response.size}");
    }
    catch(e){
      logger.w("Dirve file upload exeption occurs : $e");
    }
    finally{
      authenticateClient.close();
    }
  }


/*
  * ==============================================================
  * Methods to format given timestamp string
  */

  static String getDateTimeUpToSeconds(String timeStamp){
    String formated = timeStamp.substring(0,19) ;
    return formated;
  }

  static String getDateFromTimeStamp(String timeStamp){
    String formated = timeStamp.substring(0,10) ;
    return formated;
  }


/*
  * ==============================================================
  * A Method tto read the file
  */
  Future<void> readFile() async {
    logger.w("Test file read start====================================\n");
    print(await fileService.readFile());
  }

}