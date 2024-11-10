import 'dart:io';
import 'dart:convert'; // For JSON encoding and decoding
import 'dart:math';

final session = Session();
void main() async {
  Map<int, String> storeOptions = {
    1: "store",
    2: "view items",
    3: "log in",
    4: "register",
    5: "exit",
    6: "delete"
  };

  // SESSION
  // SESSION
  final store = Managestore();
  final auth = Auth();

  // QuerBot Explicitly specifying the type as string
  Query<String> queryBot = Query<String>();

  while (true) {
    print('\nEnter a command (or type "exit" to quit):');
    print(storeOptions);
    String? baseReply = stdin.readLineSync(); // ask the base question

    // entryLevel();
    switch (baseReply) {
      case "1":
        var item = store.store(queryBot);
        if (item != null) {
          await store.create(item);
        }
        break;
      case "2":
        await store.view();
        break;
      case "3":
        await auth.attempt(queryBot);
        break;
      case "4":
        var userData = auth.query(queryBot);
        await auth.create(userData);
        break;
      case "5":
        print('Thank u 4 using this bot, goodbye..!');
        break;
      case "6":
        await store.delete(queryBot);
        break;
      case "exit":
        print('Thank u 4 using this bot, goodbye..!');
        break;
      default:
        print('Command did not match enter a correct command');
    }

    if (baseReply == '5' || baseReply == 'exit') {
      break;
    }
  }
}

class Managestore {
  Map<String, String>? store(Query<String> queryBot) {
    if (session.checkAuth()) {
      Map<String, String> prepStoreValue() {
        final valueName = queryBot.ask('Name of what you wish to store');
        final description = queryBot.ask('A short description of your item');
        final url = queryBot.ask('Url to your item');
        final tags = queryBot.ask(
            'Any Extra tags..? [separate, with, commas] if none leave empty');
        return {
          "id": ID_SIGN(8).id(),
          "uID": session.getAuth()['uID'] as String,
          "name": valueName,
          "desc": description,
          "url": url,
          "tags": tags
        };
      }

      var item = prepStoreValue();
      print("\nYour Item in memory is $item");
      String confirmStore =
          queryBot.ask('Save or Cancel: \n[1: save..?, 2: cancel..?]');

      if (confirmStore == "1") {
        return item;
      } else {
        print("Canceled.. \n\n");
        return null; // Return null if canceled
      }
    } else {
      print('Please log in first to continue with perfoming other actions');
      return null;
    }
  }

  Future<void> create(Map<String, String>? item) async {
    // Define the file path
    final file = File('store_db.json');

    // Check if the file exists
    if (!await file.exists()) {
      // Create a new JSON file if it doesn't exist and initialize it with an empty array
      await file.writeAsString(jsonEncode([]));
    }

    // Get existing data from the db file
    String jsonString = await file.readAsString();
    List<dynamic> dbData = jsonDecode(jsonString);

    // Add new item to the existing data
    dbData.add(item);

    // Write the updated data back to db.json
    await file.writeAsString(jsonEncode(dbData), mode: FileMode.write);
    print("\nYour item has been added to the store \n ");
  }

  Future view() async {
    // Define the file path
    final file = File('store_db.json');

    if (session.checkAuth()) {
      // Check if the file exists
      if (!await file.exists()) {
        // Create a new JSON file if it doesn't exist and initialize it with an empty array
        await file.writeAsString(jsonEncode([]));
      }

      // Get existing data from the db file
      String jsonString = await file.readAsString();
      List<dynamic> dbData = jsonDecode(jsonString);

      // Parse JSON data to a List of Maps
      List<Map<String, dynamic>> items =
          List<Map<String, dynamic>>.from(dbData);

      // Function to filter items by uID
      List<Map<String, dynamic>> findItemsByUID(
          List<Map<String, dynamic>> items, String uID) {
        return items.where((item) => item["uID"] == uID).toList();
      }

      // Filter items with uID of the current logged in user
      var filteredItems =
          findItemsByUID(items, session.getAuth()['uID'] as String);

      // Pretty-print each item in the filtered list
      JsonEncoder encoder = JsonEncoder.withIndent('  ');
      if (filteredItems.length > 0) {
        print("\nYour Stored Data:");
        var counter = 0;
        for (var item in filteredItems) {
          String prettyItem = encoder.convert(item);
          print("$counter: $prettyItem");
          print("\n"); // Add an extra line for spacing
          counter++;
        }
      }
    } else {
      print('\nPlease log in first before performing this action\n');
    }
  }

  Future delete(Query<String> queryBot) async {
    // Define the file path
    final file = File('store_db.json');

    if (session.checkAuth()) {
      // Check if the file exists
      if (!await file.exists()) {
        // Create a new JSON file if it doesn't exist and initialize it with an empty array
        await file.writeAsString(jsonEncode([]));
      }

      // Get existing data from the db file
      String jsonString = await file.readAsString();
      List<dynamic> dbData = jsonDecode(jsonString);

      // Parse JSON data to a List of Maps
      List<Map<String, dynamic>> items =
          List<Map<String, dynamic>>.from(dbData);

      // Function to filter items by uID
      List<Map<String, dynamic>> findItemsByUID(
          List<Map<String, dynamic>> items, String uID) {
        return items.where((item) => item["uID"] == uID).toList();
      }

      // Filter items with uID of the current logged in user
      var filteredItems =
          findItemsByUID(items, session.getAuth()['uID'] as String);

      // Pretty-print each item in the filtered list
      JsonEncoder encoder = JsonEncoder.withIndent('  ');

      if (filteredItems.length > 0) {
        print("\nYour Stored Data:");
        var counter = 0;
        for (var item in filteredItems) {
          String prettyItem = encoder.convert(item);
          print("ID<$counter> $prettyItem");
          print("\n"); // Add an extra line for spacing
          counter++;
        }

        // question request for item ID
        final idToGoString = queryBot.ask('Enter id of the item to delete');
        if (int.parse(idToGoString) > counter) {
          print('\nID entered doest exist');
        } else {
          var idUID = filteredItems[int.parse(idToGoString)]['id'];

          filteredItems.removeWhere((item) => item["id"] == idUID);

          // Write the updated data back to db.json
          await file.writeAsString(jsonEncode(filteredItems),
              mode: FileMode.write);
          print("\nYour item has been deleted from the store \n ");
        }
      } else {
        print('\nYou Don\'t have any stored item.. Store some items first');
      }
    } else {
      print('\nPlease log in first before performing this action\n');
    }
  }
}

class Query<T> {
  T ask(String query) {
    print(query);
    dynamic reply = stdin.readLineSync();
    return reply as T;
  }
}

class Auth {
  // String? name;
  // String? email;

  // Auth(this.name, this.email);

  Future create(Map<String, String> userData) async {
    // Get the file path
    final file = File('user_db.json');

    // Check if the file exists
    if (!await file.exists()) {
      // Create a new JSON file if it doesn't exist and initialize it with an empty array
      await file.writeAsString(jsonEncode([]));
    }

    // Read existing data from the file
    String jsonString = await file.readAsString();
    List<dynamic> dbData = jsonDecode(jsonString);

    // print(dbData);
    // print(userData);

    // Parse JSON data to a List of Maps
    List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(dbData);

    // Map data with email and password to search for
    Map<String, String?> userToSearch = {
      "email": userData['email'],
      "password": userData['password']
    };

    // Function to find user
    Map<String, dynamic> findUser(
        List<Map<String, dynamic>> users, Map<String, String?> criteria) {
      return users.firstWhere(
        (user) =>
            user["email"] == criteria["email"] &&
            user["password"] == criteria["password"],
        orElse: () => {},
      );
    }

    // Search for user
    var foundUser = findUser(users, userToSearch);

    if (foundUser.isNotEmpty) {
      print(
          "\nThe details you parsed is already in use please use another one and re-register..!");
    } else {
      // print("\nUser not found.");
      // Add new item to the existing data
      dbData.add(userData);

      // Write the updated data back to db.json
      await file.writeAsString(jsonEncode(dbData), mode: FileMode.write);
      print("\nYour account has been created to the store \n");
    }
  }

  Map<String, String> query(Query<String> queryBot) {
    final username = queryBot.ask('what is your name Sir/Ma...?');
    final email = queryBot.ask('your email Address..?');
    final password = queryBot.ask('your password Address..?');
    final specialUID = new ID_SIGN(10).id();
    return {
      "uID": specialUID,
      "username": username,
      "email": email,
      "password": password
    };
  }

  Future attempt(Query<String> queryBot) async {
    final email = queryBot.ask('your email Address..?');
    final password = queryBot.ask('your password Address..?');
    // Get the file path
    final file = File('user_db.json');

    // Check if the file exists
    if (!await file.exists()) {
      // Create a new JSON file if it doesn't exist and initialize it with an empty array
      await file.writeAsString(jsonEncode([]));
    }

    // Read existing data from the file
    String jsonString = await file.readAsString();
    List<dynamic> dbData = jsonDecode(jsonString);

    // print(dbData);
    // print(userData);

    // Parse JSON data to a List of Maps
    List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(dbData);

    // Map data with email and password to search for
    Map<String, String?> userToSearch = {"email": email, "password": password};

    // Function to find user
    Map<String, dynamic> findUser(
        List<Map<String, dynamic>> users, Map<String, String?> criteria) {
      return users.firstWhere(
        (user) =>
            user["email"] == criteria["email"] &&
            user["password"] == criteria["password"],
        orElse: () => {},
      );
    }

    // Search for user
    var foundUser = findUser(users, userToSearch);

    if (foundUser.isNotEmpty) {
      print(
          "\nU have successfully logged in please continue with other acctions");
      session.setAuth(foundUser['uID'], foundUser['password']);
    } else {
      print("\nUser not found please create an account first.");
    }
  }
}

class Session {
  bool isAuth = false;
  String userID = '';
  String email = '';

  void setAuth(String theUserID, String theEmail) {
    isAuth = true;
    userID = theUserID;
    email = theEmail;
  }

  bool checkAuth() {
    return isAuth;
  }

  Map<String, String> getAuth() {
    return {"uID": this.userID, "email": this.email};
  }

  void unset() {
    isAuth = false;
    userID = '';
    email = '';
  }
}

class User {
  String name = '';
  String email = '';

  void setUser(String theName, String theEmail) {
    name = theName;
    email = theEmail;
  }

  create() async {
    final file = File('user_db.json');

    // Check if the file exists
    if (!await file.exists()) {
      // Create a new JSON file if it doesn't exist and initialize it with an empty array
      await file.writeAsString(jsonEncode([]));
    }

    // Read existing data from the file
    String jsonString = await file.readAsString();
    List<dynamic> dbData = jsonDecode(jsonString);

    print(dbData);
  }
}

class ID_SIGN {
  int lenght;

  ID_SIGN(this.lenght);

  String generateRandomString(int length) {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();

    return List.generate(
            length, (index) => characters[random.nextInt(characters.length)])
        .join();
  }

  String id() {
    String randomString = generateRandomString(this.lenght);
    return randomString;
  }
}
