// ignore_for_file: file_names
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class PublicHolidayService{
  late String api_key;
  late String country;
  late String year;
  late var holidays;


  PublicHolidayService({required this.api_key, required this.country, required this.year});

  Future<void> getPublicHolidayData ()async{

    final queryParameters= {
      'api_key':api_key,
      'country': country,
      'year':year
    };

    final uri = Uri.https('www.calendarific.com', '/api/v2/holidays',queryParameters);
    final response = await http.get(uri);

    
    if(response.statusCode == 200){ // if data recieved
      Map  locationData = convert.jsonDecode(response.body);
      // print(locationData);
      holidays = locationData["response"]["holidays"];
    }
    else{ // if any error occurrs 
        print("API response failed with status : ${response.statusCode}.");
    }
  
  }

/*
 *  =================================================================================
 *  A method to check is given date is a holiday
 */
  bool checkIsHoliday(String date){
    bool isHoliday = false;

     for(int holiday =0; holiday < holidays.length; holiday++){

        String currentHoliday = holidays[holiday]["date"]["iso"].substring(0,10);

        if(date.trim() == currentHoliday.trim()){
          isHoliday = true;
        }
      }
    return isHoliday;
  }
}