 // ignore_for_file: file_names
class FileRecord {
   late String longitude;
   late String latitude;
   late String timeStamp;
   late bool isRushHour;
   late bool isWeekend;
   late bool isPublicHoliday;

   FileRecord({
     required this.longitude,
     required this.latitude, 
     required this.timeStamp,
     required this.isRushHour, 
     required this.isWeekend,
     required this.isPublicHoliday
     });

     Map<String, dynamic> toJson()=> {
       "longitude" : longitude,
       'latitude' : latitude,
       'timestamp' : timeStamp,
       'isRushHour' : isRushHour,
       'isWeekend' : isWeekend,
       'isPublichHolidy' : isPublicHoliday
     };
 }