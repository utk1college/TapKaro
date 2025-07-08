import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

const String baseUrl = "https://backendpayment.onrender.com";

// Register Usera
Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
  final requestBody = {
    "username": userData['username'],
    "email": userData['email'],
    "password": userData['password'],
    "phone_number": userData['phone_number'] ?? "",
    "first_name": userData['first_name'] ?? "",
    "last_name": userData['last_name'] ?? "",
    "date_of_birth": userData['date_of_birth'] ?? "1990-01-01"
  };

  final response = await http.post(
    Uri.parse('$baseUrl/api/auth/register'),
    headers: {'Content-Type': 'application/json; charset=UTF-8'},
    body: jsonEncode(requestBody),
  );

  final responseBody = jsonDecode(response.body);
  if (response.statusCode == 200) {
    return {
      'user': responseBody['user'],
      'token': responseBody['token'],
      'token_expiry': responseBody['token_expiry']
    };
  } else {
    throw Exception('Failed to register user: ${responseBody['error'] ?? responseBody['details'] ?? 'Unknown error'}');
  }
}

// Login User
Future<Map<String, dynamic>> loginUser(String identifier, String password) async {
  final requestBody = {
    'identifier': identifier,
    'password': password,
  };

  final response = await http.post(
    Uri.parse('$baseUrl/api/auth/login'),
    headers: {'Content-Type': 'application/json; charset=UTF-8'},
    body: jsonEncode(requestBody),
  );

  final responseBody = jsonDecode(response.body);
  if (response.statusCode == 200) {
    return {
      'user': responseBody['user'],
      'token': responseBody['token'],
      'token_expiry': responseBody['token_expiry']
    };
  } else {
    throw Exception('Failed to login: ${responseBody['error'] ?? responseBody['details'] ?? 'Unknown error'}');
  }
}

// Initiate Online Payment
Future<Map<String, dynamic>> initiateOnlinePayment(
    String token, String senderId, String recipientId, double amount, {String description = "Payment from TapKaro app"}) async {
  final payload = {
    "recipient_id": recipientId,
    "amount": amount,
    "currency": "INR",
    "description": description,
    "transaction_type": "P2P",
    "timestamp": DateTime.now().toUtc().toIso8601String(),
  };

  final response = await http.post(
    Uri.parse('$baseUrl/api/payment/initiate'),
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(payload),
  );

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    return {
      "payment_id": responseData["payment_id"],
      "status": responseData["status"],
      "sender_transaction_id": responseData["sender_transaction_id"],
      "recipient_transaction_id": responseData["recipient_transaction_id"],
      "created_at": responseData["created_at"],
      "updated_at": responseData["updated_at"]
    };
  } else {
    final errorData = jsonDecode(response.body);
    throw Exception('Payment failed: ${errorData['error'] ?? errorData['message'] ?? 'Unknown error'}');
  }
}

// Sync Offline Transaction
Future<Map<String, dynamic>> syncOfflineTransaction(
    String token, String recipientIdentifier, double amount) async {
  const uuid = Uuid();
  final localTxId = uuid.v4();
  final deviceId = "device-${uuid.v4().substring(0, 8)}";
  final timestamp = DateTime.now().toUtc().toIso8601String();
  final sigStr = '$localTxId|$recipientIdentifier|$amount|INR|$timestamp';
  final encryptedData = sha256.convert(utf8.encode(sigStr)).toString();

  final payload = {
    "device_id": deviceId,
    "transactions": [{
      "local_transaction_id": localTxId,
      "recipient_identifier": recipientIdentifier,
      "amount": amount,
      "currency": "INR",
      "timestamp": timestamp,
      "encrypted_data": encryptedData,
    }],
  };

  final response = await http.post(
    Uri.parse('$baseUrl/api/offline/sync'),
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(payload),
  );

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    return {
      "sync_id": responseData["sync_id"],
      "synced_transaction_details": responseData["synced_transaction_details"],
      "failed_transactions": responseData["failed_transactions"] ?? [],
      "sync_completed_at": responseData["sync_completed_at"]
    };
  } else {
    final responseBody = jsonDecode(response.body);
    throw Exception('Failed to sync offline transaction: ${responseBody['error'] ?? responseBody['message'] ?? 'Unknown error'}');
  }
}

// Fetch All Transactions
Future<List<dynamic>> fetchAllTransactions(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/transactions'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return [];
  }
}

// Get Wallet Balance
Future<Map<String, dynamic>> getWalletBalance(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/wallet'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      "wallet_id": data["wallet_id"],
      "user_id": data["user_id"],
      "balance": data["balance"],
      "currency": data["currency"],
      "created_at": data["created_at"],
      "updated_at": data["updated_at"]
    };
  } else {
    final responseBody = jsonDecode(response.body);
    throw Exception('Failed to get wallet balance: ${responseBody['error'] ?? responseBody['message'] ?? 'Unknown error'}');
  }
}


Future<Map<String, dynamic>> addFundsToWallet(String token, double amount) async {
  if (amount <= 0) {
    throw Exception('Invalid amount: Amount must be greater than zero.');
  }

  final response = await http.post(
    Uri.parse('$baseUrl/api/wallet/topup'), // ✅ Corrected endpoint
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'amount': amount}),
  );

  final responseBody = jsonDecode(response.body);
  if (response.statusCode == 200) {
    final wallet = responseBody['wallet'] ?? {};
    return {
      'status': 'success',
      'message': responseBody['message'] ?? 'Balance topped up successfully.',
      'transaction_id': responseBody['transaction_id'],
      'added_amount': amount,
      'new_balance': wallet['balance'],
      'updated_at': responseBody['updated_at'],
    };
  } else {
    throw Exception('Failed to top up wallet: ${responseBody['error'] ?? responseBody['message'] ?? 'Unknown error'}');
  }
}

// ✅ Search User by Phone Number
Future<Map<String, dynamic>?> searchUserByPhone(String token, String phoneNumber) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/by-phone?phone_number=$phoneNumber'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Failed to search user: ${error['error'] ?? 'Unknown error'}');
    }
  } catch (e) {
    print('Search error: $e');
    return null;
  }
}
class ApiContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? createdAt; // Optional

  ApiContact({required this.id, required this.name, required this.phoneNumber, this.createdAt});

  factory ApiContact.fromJson(Map<String, dynamic> json) {
    return ApiContact(
      id: json['id'],
      name: json['contact_name'], // Ensure these keys match your backend response
      phoneNumber: json['contact_phone_number'],
      createdAt: json['created_at'],
    );
  }
}

Future<List<ApiContact>> getContacts(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/contacts'),
      headers: {'Authorization': 'Bearer $token'},
    ); //.timeout(_defaultTimeout); // Consider adding timeout back if removed above

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => ApiContact.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      // Try to parse error
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to get contacts: ${errorBody['error'] ?? response.body}');
      } catch (_) {
         throw Exception('Failed to get contacts: ${response.statusCode}');
      }
    }
  } catch (e) {
    print('Error fetching contacts: $e');
    throw Exception('Failed to fetch contacts: ${e.toString()}');
  }
}

Future<ApiContact> addContact(String token, String name, String phoneNumber) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/contacts'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'phoneNumber': phoneNumber}),
    ); //.timeout(_defaultTimeout);

    if (response.statusCode == 201) {
      return ApiContact.fromJson(jsonDecode(response.body));
    } else {
       try {
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to add contact: ${errorBody['error'] ?? response.body}');
      } catch (_) {
         throw Exception('Failed to add contact: ${response.statusCode}');
      }
    }
  } catch (e) {
    print('Error adding contact: $e');
    throw Exception('Failed to add contact: ${e.toString()}');
  }
}

Future<void> deleteContact(String token, String contactId) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/contacts/$contactId'),
      headers: {'Authorization': 'Bearer $token'},
    ); //.timeout(_defaultTimeout);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return; // Success
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to delete contact: ${errorBody['error'] ?? errorBody['message'] ?? 'Unknown error'}');
      } catch (_) {
         throw Exception('Failed to delete contact: ${response.statusCode}');
      }
    }
  } catch (e) {
    print('Error deleting contact: $e');
    throw Exception('Failed to delete contact: ${e.toString()}');
  }
}
// api_service.dart
// ... (existing code)

// Optional: Fetch User Details by ID
Future<Map<String, dynamic>?> getUserDetailsById(String token, String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/$userId'), // Assuming endpoint like /api/user/:id
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Expects { "user": { ... } } or just { ... }
    } else if (response.statusCode == 404) {
      return null;
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Failed to fetch user details: ${error['error'] ?? 'Unknown error'}');
    }
  } catch (e) {
    print('Error fetching user details by ID: $e');
    return null; // Or rethrow
  }
}