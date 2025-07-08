// contact_screen.dart
import 'package:flutter/material.dart';
import 'package:payment_app/services/api_service.dart'; // Import your API service
import 'package:payment_app/utils/theme.dart'; // Import OLD AppTheme
import 'package:payment_app/utils/common_widgets.dart'; // For commonAppBar
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For token

// Contact Model used within this screen
class Contact {
  String id; // Database ID
  String name;
  String phoneNumber;
  String? createdAt; // Optional

  Contact({required this.id, required this.name, required this.phoneNumber, this.createdAt});

  factory Contact.fromApiContact(ApiContact apiContact) {
    return Contact(
      id: apiContact.id,
      name: apiContact.name,
      phoneNumber: apiContact.phoneNumber,
      createdAt: apiContact.createdAt,
    );
  }
}

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  List<Contact> _contacts = [];
  bool _isLoading = true;
  String? _error; // To display errors

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For the add contact dialog form
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadContactsFromApi();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // --- Data Loading Functions (Keep functional logic) ---
  Future<void> _loadContactsFromApi() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Auth token not found.');
      final apiContacts = await getContacts(token);
      if (mounted) {
        setState(() {
          _contacts = apiContacts.map((apiC) => Contact.fromApiContact(apiC)).toList();
          _contacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _error = e.toString().replaceFirst("Exception: ", ""); });
        ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Failed to load contacts: $_error'), backgroundColor: AppTheme.errorColor, ), ); // Use OLD AppTheme.errorColor
      }
    }
  }

  Future<void> _addContactToApi() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim(); final phone = _phoneController.text.trim();
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark; // Check theme mode for dialog

    showDialog( context: context, barrierDismissible: false, builder: (BuildContext context) {
        return AlertDialog(
          // Use OLD theme colors for dialog
           backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.9) : Colors.white, // Old darkSurfaceColor or white
           content: Row( children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(isDarkMode ? Colors.white : AppTheme.primaryColor)), // Spinner color based on mode
              const SizedBox(width: 20),
              Text("Saving...", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
            ],
          ),
        );
      },
    );

    try {
      final token = await _getToken(); if (token == null) throw Exception('Auth token not found.');
      final newApiContact = await addContact(token, name, phone);
      Navigator.of(context).pop(); // Pop loading
      if (mounted) {
        Navigator.of(context).pop(); // Pop add contact dialog
        final newContact = Contact.fromApiContact(newApiContact);
        setState(() { _contacts.add(newContact); _contacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); });
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('${newContact.name} added.'), backgroundColor: Colors.green), );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Pop loading
      if (mounted) { String errorMsg = e.toString().replaceFirst("Exception: ", ""); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Failed to add: $errorMsg'), backgroundColor: AppTheme.errorColor), ); } // Use OLD errorColor
    }
  }

  Future<void> _deleteContactFromApi(BuildContext parentDialogContext, String contactId, int listIndex) async { // Renamed context
    final contactToRemove = _contacts[listIndex];
    final bool isDarkMode = Theme.of(parentDialogContext).brightness == Brightness.dark;

    bool? confirmDelete = await showDialog<bool>( context: parentDialogContext,
        builder: (BuildContext dContext) => AlertDialog( // Confirmation Dialog
           title: Text('Delete Contact', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
           content: Text('Delete ${contactToRemove.name}?', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
           backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.8) : Colors.white, // OLD darkSurfaceColor or white
           actions: <Widget>[
              TextButton( child: Text('Cancel', style: TextStyle(color: isDarkMode ? Colors.white70 : AppTheme.accentColor)), onPressed: () => Navigator.of(dContext).pop(false), ),
              TextButton( child: Text('Delete', style: TextStyle(color: AppTheme.errorColor)), onPressed: () => Navigator.of(dContext).pop(true), ), // Use OLD errorColor
           ],
        ));

    if (confirmDelete == true) {
       setState(() { _contacts.removeAt(listIndex); }); // Optimistic remove
       try {
          final token = await _getToken(); if (token == null) throw Exception('Token not found.');
          await deleteContact(token, contactId);
          if (mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('${contactToRemove.name} removed.'), backgroundColor: Colors.orangeAccent), ); }
       } catch (e) {
          if (mounted) {
             setState(() { _contacts.insert(listIndex, contactToRemove); _contacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); }); // Revert
             String errorMsg = e.toString().replaceFirst("Exception: ", "");
             ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Failed to delete: $errorMsg'), backgroundColor: AppTheme.errorColor), ); // Use OLD errorColor
          }
       }
    }
  }

  // Show Add Contact Dialog - Styled according to OLD code patterns
  void _showAddContactDialog(BuildContext parentContext) {
    _nameController.clear(); _phoneController.clear();
    final bool isDarkMode = Theme.of(parentContext).brightness == Brightness.dark;

    showDialog( context: parentContext,
      builder: (BuildContext dialogContext) => AlertDialog(
         // Use colors/styles resembling OLD AppTheme's DialogTheme if possible, or direct constants
         backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.8) : Colors.white, // Match OLD dark dialog
         title: Text('Add New Contact', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)), // Match OLD dark dialog title
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Match OLD dialog shape
         contentPadding: const EdgeInsets.all(20),
         content: Form( key: _formKey,
          child: Column( mainAxisSize: MainAxisSize.min, children: [
              TextFormField( // Name Field
                controller: _nameController,
                 // Use the static inputDecoration but ensure colors match OLD context if possible
                 decoration: AppTheme.inputDecoration(
                    hintText: 'Contact Name', // Use hintText
                    isDarkMode: isDarkMode,
                 ).copyWith(
                    // Override defaults from static method if needed to match old theme
                    // Example: Use text colors consistent with dialog background
                    hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600),
                    labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                    // fillColor: isDarkMode ? Colors.white.withOpacity(0.07) : Colors.grey.shade100, // Match old input fill
                    // enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isDarkMode ? BorderSide(color: Colors.white.withOpacity(0.2), width: 1) : BorderSide.none),
                    // focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isDarkMode ? BorderSide(color: Colors.white.withOpacity(0.5), width: 1) : BorderSide(color: AppTheme.accentColor, width: 1)),
                 ),
                 style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87), // Text input color
                 validator: (value) { if (value == null || value.isEmpty) return 'Please enter a name'; return null; },
              ),
              const SizedBox(height: 16),
              TextFormField( // Phone Field
                 controller: _phoneController,
                 decoration: AppTheme.inputDecoration(
                    hintText: 'Phone Number',
                    isDarkMode: isDarkMode,
                    prefixIcon: Icons.phone_outlined,
                 ).copyWith(
                     hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600),
                     labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                    //  fillColor: isDarkMode ? Colors.white.withOpacity(0.07) : Colors.grey.shade100,
                    //  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isDarkMode ? BorderSide(color: Colors.white.withOpacity(0.2), width: 1) : BorderSide.none),
                    //  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isDarkMode ? BorderSide(color: Colors.white.withOpacity(0.5), width: 1) : BorderSide(color: AppTheme.accentColor, width: 1)),
                 ),
                 style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                 keyboardType: TextInputType.phone,
                 validator: (value) { if (value == null || value.isEmpty) return 'Please enter phone'; if (!RegExp(r'^\+?[0-9]{10,14}$').hasMatch(value)) return 'Enter a valid number'; return null; },
              ),
             ],
          ),
        ),
         actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
         actions: [
           TextButton( // Use OLD TextButton styling
             onPressed: () => Navigator.of(dialogContext).pop(),
             child: Text('Cancel', style: TextStyle(color: isDarkMode ? Colors.white : AppTheme.accentColor, fontWeight: FontWeight.bold)), // Match OLD dark/light button text
           ),
           ElevatedButton( // Use OLD ElevatedButton Styling
             onPressed: _addContactToApi,
             style: ElevatedButton.styleFrom( // Derive from OLD ElevatedButtonTheme
                backgroundColor: isDarkMode ? Colors.white.withOpacity(0.15) : AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: Size.zero, // Let button size itself
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             ),
             child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
           ),
         ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Use brightness like old code
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Use direct Theme constants where appropriate as per old code
    final Color scaffoldBg = isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor; // Old theme bg constants
    final Color appBarIconColor = isDarkMode ? Colors.white : Colors.black; // Old app bar icon color
    final Color appBarBg = isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor; // Old app bar bg might match scaffold

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: commonAppBar(
        title: 'My Contacts',
        context: context,
        // Pass old styling parameters if commonAppBar supports them
        // backgroundColor: appBarBg,
        // iconThemeColor: appBarIconColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: appBarIconColor), // Use old icon color
            onPressed: _isLoading ? null : _loadContactsFromApi,
            tooltip: 'Refresh Contacts',
          )
        ],
      ),
      body: Builder(
        builder: (BuildContext scaffoldContext) {
          // --- Loading State (Simple) ---
          if (_isLoading && _contacts.isEmpty) {
            return Center(child: CircularProgressIndicator(color: isDarkMode ? Colors.white70 : AppTheme.primaryColor)); // Simple spinner
          }
          // --- Error State (Simple) ---
          if (_error != null && _contacts.isEmpty) {
             return Center( child: Padding( padding: const EdgeInsets.all(24.0),
                child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 60),
                    const SizedBox(height: 16),
                    Text( 'Failed to load contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70: Colors.black54)),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: isDarkMode ? Colors.white60 : Colors.grey.shade700)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon( // Use OLD button style
                      onPressed: _loadContactsFromApi, icon: const Icon(Icons.refresh), label: const Text('Retry'),
                       style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor, // Example button colors
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                    )
                  ],
                ),
              ));
          }
           // --- Empty State (OLD Style) ---
          if (_contacts.isEmpty) {
             return Center(
                child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400), // Match old icon/color
                    const SizedBox(height: 16),
                    Text( 'No contacts saved yet.', style: TextStyle(fontSize: 18, color: Colors.grey.shade600), ),
                    const SizedBox(height: 8),
                    Text( 'Tap the "+" button to add your first contact.', style: TextStyle(fontSize: 14, color: Colors.grey.shade500), textAlign: TextAlign.center,),
                  ],
                ),
              );
          }
          // --- Contact List (OLD Style) ---
          return ListView.builder(
            padding: const EdgeInsets.all(8.0), // Old padding
            itemCount: _contacts.length,
            itemBuilder: (context, index) {
              final contact = _contacts[index];
              final initial = contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?';
              // Use OLD Card and ListTile Styling
              return Card(
                elevation: 2, // Old elevation
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), // Old margin
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Old shape
                color: isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.5) : Colors.white, // Old colors
                child: ListTile(
                  leading: CircleAvatar( // Old Avatar Style
                    backgroundColor: AppTheme.accentColor.withOpacity(0.1), // Old background
                    // Ensure text contrasts with OLD background
                    child: Text( initial, style: TextStyle(color: isDarkMode? Colors.white : AppTheme.accentColor, fontWeight: FontWeight.bold), ),
                  ),
                  title: Text(contact.name, style: TextStyle(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black87)), // Old text style
                  subtitle: Text(contact.phoneNumber, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade700)), // Old text style
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade300), // Old delete icon style
                     // Pass scaffoldContext for the confirmation dialog
                    onPressed: () => _deleteContactFromApi(scaffoldContext, contact.id, index),
                    tooltip: "Delete ${contact.name}",
                  ),
                  onTap: () { Navigator.of(context).pop(contact.phoneNumber); },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(context),
        // Use OLD FAB colors
        backgroundColor: AppTheme.accentColor,
        tooltip: 'Add Contact',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}