
// ignore_for_file: file_names, slash_for_doc_comments

import 'package:geolocator/geolocator.dart';

class GeolocatorService {
  
  /**
   * A method to get current location of the device
   */

  Future<Position> getCurrentPosition() async {

    bool isServiceEnabled; // to store geo service status of the device
    LocationPermission permission; // store location permission on deveice

    // Check locaion service is enabled
    isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!isServiceEnabled){
      // Location servcies are not enabled
      // Stop here
      return Future.error("Location Services are disabled.");
    }

    // check device permission is granted
    permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied){
      permission = await Geolocator.requestPermission();
      
      if(permission == LocationPermission.denied){
        // Permissions are still denied
        return Future.error("Location Permissions are denied");
      }
    }

    if(permission == LocationPermission.deniedForever){
      // when permissions are denied forever
      return Future.error('Location permissions are permanently denied, cannot request permision');

    }

    // if all satisfied, get current geo location
    return await Geolocator.getCurrentPosition();
  }
}