
// ignore_for_file: file_names

import 'package:intl/intl.dart';

class TimeService{
  late String timeStamp;
  late DateTime now;

  TimeService(){
    now =DateTime.now();
    timeStamp = now.toString();
  }

 String getCurrentDate(){
   return timeStamp.substring(0,10);
 }

  // check is rush hours. Rush hours -> {7am - 9am, 4pm - 7pm}
  bool checkIsRushHour(){
    int currentHour = int.parse(timeStamp.substring(11,13));
    bool isRushHour= false; // store is current hour is a rush hour. initially not a rush hour.
    
    if ((currentHour >= 7 && currentHour <= 9) || (currentHour >= 16 && currentHour <= 19)){
      // if is a rush hour
      isRushHour = true;
    }

    return isRushHour;
  }

  bool  checkIsWeekend(){
    bool isWeekend = false;
    String today = DateFormat("EEEE").format(now);

    if( today == "Saturday" || today == "Sunday" ){
      isWeekend = true;
    }
    return isWeekend;
  }

  String getTimeStamp(){
    return timeStamp;
  }

}