// ignore_for_file: file_names

import "dart:io";
import 'package:path_provider/path_provider.dart';

class FileService {
  late String fileName;
  late File file;
  late bool isFileEmpty;

  FileService({required String this.fileName});


  // Setting up local file in external memory
  Future<void> setLocalFile() async {
    var directory =  await getExternalStorageDirectory();
    print("Path : ${directory!.path}");
    file = File('${directory!.path}/$fileName');
  }


  // method to write content to the file
  Future<File> writeContent(String content)async{
    if(isFileEmpty){
      return file.writeAsString(content);
    }
    else{
      return file.writeAsString(","+content,mode: FileMode.append);
    }
  }

  // A method to read file
  Future<String> readFile()async{
    late String content;
    try{
      if(await file.exists()){
        content = await file.readAsString();
      }
      else{
        print("File : ${file.toString()} - not found !");
        content = "Not found"; 
      }
    }
    catch(e){
      print("=========================================================");
      print("File read exception was occurred : $e \n");
    }
    return content;
  }

  /*
   * A method to wipe data in the file
   */
  void clearFile(){
    file.writeAsString("");
  }


 // A method to check is file is empty
  Future <void> checkFileEmpty() async{
     String content = await readFile();
    if(content=="" || content == "Not found"){
      isFileEmpty = true;
    }
    else{
      isFileEmpty = false;
    }
  }


  // A method to finally format the file in to propper JSON format
  Future <void> fileFormatToJSON()async{
    String content = await readFile();
    clearFile();
    file.writeAsString("{\"records\":[$content]}");
  }

 

  /*
   * A getters and setters -----------------------------------------
   */
  
  File getFile(){
    return file;
  }

}