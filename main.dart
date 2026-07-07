
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Lost & Found',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LostFoundHomePage(),
    );
  }
}

// ==================== MODELS ====================

enum LostItemStatus { lost, found, claimed }

enum ItemCategory { electronics, books, clothing, accessories, documents, others }

extension CategoryExtension on ItemCategory {
  String get displayName {
    switch (this) {
      case ItemCategory.electronics:
        return 'Electronics';
      case ItemCategory.books:
        return 'Books';
      case ItemCategory.clothing:
        return 'Clothing';
      case ItemCategory.accessories:
        return 'Accessories';
      case ItemCategory.documents:
        return 'Documents';
      case ItemCategory.others:
        return 'Others';
    }
  }

  IconData get icon {
    switch (this) {
      case ItemCategory.electronics:
        return Icons.computer;
      case ItemCategory.books:
        return Icons.book;
      case ItemCategory.clothing:
        return Icons.checkroom;
      case ItemCategory.accessories:
        return Icons.watch;
      case ItemCategory.documents:
        return Icons.description;
      case ItemCategory.others:
        return Icons.category;
    }
  }
}

class LostItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final DateTime date;
  final LostItemStatus status;
  final String? imageBase64;
  final String? contactEmail;
  final String? contactPhone;

  LostItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.date,
    this.status = LostItemStatus.lost,
    this.imageBase64,
    this.contactEmail,
    this.contactPhone,
  });

  LostItem copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    DateTime? date,
    LostItemStatus? status,
    String? imageBase64,
    String? contactEmail,
    String? contactPhone,
  }) {
    return LostItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      date: date ?? this.date,
      status: status ?? this.status,
      imageBase64: imageBase64 ?? this.imageBase64,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }
}

// ==================== IMAGE PICKER SERVICE ====================

class ImagePickerService {
  static bool get isWeb {
    // ignore: avoid_web_libraries_in_flutter
    return identical(0, 0.0) ? false : true;
  }

  static Future<String?> pickImageFromGallery() async {
    try {
      if (isWeb) {
        // Web: Use FilePicker
        return await _pickImageWithFilePicker();
      } else {
        // Mobile/Desktop: Use ImagePicker
        if (Platform.isAndroid || Platform.isIOS) {
          final status = await Permission.photos.request();
          if (!status.isGranted) return null;
        }

        final picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 80,
        );

        if (image == null) return null;
        final bytes = await image.readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  static Future<String?> takePhoto() async {
    try {
      if (isWeb) {
        // Web: Use FilePicker for camera
        return await _pickImageWithFilePicker();
      } else {
        // Mobile/Desktop: Use ImagePicker camera
        if (Platform.isAndroid || Platform.isIOS) {
          final status = await Permission.camera.request();
          if (!status.isGranted) return null;
        }

        final picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 80,
        );

        if (image == null) return null;
        final bytes = await image.readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  static Future<String?> _pickImageWithFilePicker() async {
    try {
      // For web, we need to use FilePicker
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // This is required to get the bytes
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null && file.bytes!.isNotEmpty) {
          return base64Encode(file.bytes!);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error with FilePicker: $e');
      return null;
    }
  }
}

// ==================== HOME PAGE ====================

class LostFoundHomePage extends StatefulWidget {
  const LostFoundHomePage({super.key});

  @override
  State<LostFoundHomePage> createState() => _LostFoundHomePageState();
}

class _LostFoundHomePageState extends State<LostFoundHomePage> {
  final List<LostItem> _items = [];
  List<LostItem> _filteredItems = [];
  ItemCategory? _selectedCategory;
  LostItemStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    _items.addAll([
      LostItem(
        id: '1',
        title: 'MacBook Pro',
        description: 'Silver MacBook Pro 14-inch with M1 chip, found in the library',
        category: 'Electronics',
        location: 'University Library, 3rd Floor',
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: LostItemStatus.found,
        contactEmail: 'library@campus.edu',
        contactPhone: '+1234567890',
      ),
      LostItem(
        id: '2',
        title: 'Calculus Textbook',
        description: 'Thomas Calculus 14th Edition, lost near the cafeteria',
        category: 'Books',
        location: 'Main Cafeteria',
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: LostItemStatus.lost,
        contactEmail: 'student@campus.edu',
      ),
      LostItem(
        id: '3',
        title: 'Student ID Card',
        description: 'Lost near the gymnasium, contains student photo',
        category: 'Documents',
        location: 'Gymnasium',
        date: DateTime.now().subtract(const Duration(hours: 5)),
        status: LostItemStatus.lost,
      ),
      LostItem(
        id: '4',
        title: 'Black Backpack',
        description: 'North Face backpack with laptop inside',
        category: 'Accessories',
        location: 'Computer Science Building',
        date: DateTime.now().subtract(const Duration(days: 3)),
        status: LostItemStatus.found,
        contactPhone: '+1234567890',
      ),
    ]);
    _applyFilters();
  }

  void _addItem(LostItem item) {
    setState(() {
      _items.insert(0, item);
      _applyFilters();
    });
  }

  void _updateItemStatus(String id, LostItemStatus newStatus) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index] = _items[index].copyWith(status: newStatus);
        _applyFilters();
      }
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _items.where((item) {
        final categoryMatch = _selectedCategory == null ||
            item.category == _selectedCategory!.displayName;
        final statusMatch = _selectedStatus == null ||
            item.status == _selectedStatus;
        return categoryMatch && statusMatch;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedStatus = null;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Lost & Found'),
        elevation: 2,
        actions: [
          PopupMenuButton<ItemCategory>(
            icon: const Icon(Icons.filter_list),
            onSelected: (category) {
              setState(() {
                _selectedCategory = _selectedCategory == category ? null : category;
                _applyFilters();
              });
            },
            itemBuilder: (context) => ItemCategory.values
                .map((category) => PopupMenuItem(
                      value: category,
                      child: Text(category.displayName),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilters(),
          const Divider(),
          Expanded(child: _buildItemList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Filter by status: '),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('All', null),
                  _buildChip('Lost', LostItemStatus.lost),
                  _buildChip('Found', LostItemStatus.found),
                  _buildChip('Claimed', LostItemStatus.claimed),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, LostItemStatus? status) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = selected ? status : null;
            _applyFilters();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue,
      ),
    );
  }

  Widget _buildItemList() {
    if (_filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No items found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) => _buildItemCard(_filteredItems[index]),
    );
  }

  Widget _buildItemCard(LostItem item) {
    final statusInfo = _getStatusInfo(item.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusInfo.color.withValues(alpha: 0.2),
          child: Icon(statusInfo.icon, color: statusInfo.color),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.category} • ${item.status.name}'),
            Text('📍 ${item.location}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.imageBase64 != null) const Icon(Icons.photo, size: 20),
            const SizedBox(width: 8),
            if (item.status != LostItemStatus.claimed)
              TextButton(
                onPressed: () => _showClaimDialog(item),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  item.status == LostItemStatus.found ? 'Claim' : 'Mark Found',
                  style: TextStyle(
                    color: item.status == LostItemStatus.found ? Colors.blue : Colors.green,
                  ),
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.imageBase64 != null) _buildImage(item.imageBase64!),
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(item.description),
                const SizedBox(height: 12),
                _buildInfoRow('Location:', item.location),
                _buildInfoRow('Date:', _formatDate(item.date)),
                if (item.contactEmail != null) _buildInfoRow('Email:', item.contactEmail!),
                if (item.contactPhone != null) _buildInfoRow('Phone:', item.contactPhone!),
                const SizedBox(height: 16),
                _buildActionButtons(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String base64Image) {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: MemoryImage(base64Decode(base64Image)),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(LostItem item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (item.status == LostItemStatus.lost)
          ElevatedButton.icon(
            onPressed: () => _updateItemStatus(item.id, LostItemStatus.found),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Mark as Found'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        if (item.status == LostItemStatus.found)
          ElevatedButton.icon(
            onPressed: () => _showClaimDialog(item),
            icon: const Icon(Icons.person, size: 16),
            label: const Text('Claim Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  ({Color color, IconData icon}) _getStatusInfo(LostItemStatus status) {
    switch (status) {
      case LostItemStatus.lost:
        return (color: Colors.red, icon: Icons.warning_amber_rounded);
      case LostItemStatus.found:
        return (color: Colors.green, icon: Icons.check_circle);
      case LostItemStatus.claimed:
        return (color: Colors.blue, icon: Icons.assignment_turned_in);
    }
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(onItemAdded: _addItem),
    );
  }

  void _showClaimDialog(LostItem item) {
    showDialog(
      context: context,
      builder: (context) => ClaimDialog(item: item, onClaim: () {
        _updateItemStatus(item.id, LostItemStatus.claimed);
      }),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ==================== CLAIM DIALOG ====================

class ClaimDialog extends StatefulWidget {
  final LostItem item;
  final VoidCallback onClaim;

  const ClaimDialog({super.key, required this.item, required this.onClaim});

  @override
  State<ClaimDialog> createState() => _ClaimDialogState();
}

class _ClaimDialogState extends State<ClaimDialog> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Claim'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Are you sure you want to claim this item?', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('Item: ${widget.item.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Location: ${widget.item.location}'),
          const SizedBox(height: 16),
          const Text('Contact Information:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Your email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              hintText: 'Your phone number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onClaim();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item claimed successfully!'), backgroundColor: Colors.green),
            );
          },
          child: const Text('Confirm Claim'),
        ),
      ],
    );
  }
}

// ==================== ADD ITEM DIALOG ====================

class AddItemDialog extends StatefulWidget {
  final Function(LostItem) onItemAdded;

  const AddItemDialog({super.key, required this.onItemAdded});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  ItemCategory _category = ItemCategory.others;
  LostItemStatus _status = LostItemStatus.lost;
  String? _imageBase64;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);

    String? base64;
    if (source == ImageSource.gallery) {
      base64 = await ImagePickerService.pickImageFromGallery();
    } else {
      base64 = await ImagePickerService.takePhoto();
    }

    if (base64 != null && mounted) {
      setState(() => _imageBase64 = base64);
      _showSnackBar(
        source == ImageSource.gallery ? 'Image selected!' : 'Photo taken!',
        Colors.green,
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 1)),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_imageBase64 != null) {
      return Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: MemoryImage(base64Decode(_imageBase64!)),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.change_circle),
                label: const Text('Change'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => setState(() => _imageBase64 = null),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      );
    }

    return ElevatedButton.icon(
      onPressed: _showImageSourceDialog,
      icon: const Icon(Icons.add_photo_alternate),
      label: const Text('Add Photo'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final item = LostItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category.displayName,
        location: _locationController.text,
        date: DateTime.now(),
        status: _status,
        imageBase64: _imageBase64,
        contactEmail: _emailController.text.isNotEmpty ? _emailController.text : null,
        contactPhone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );

      widget.onItemAdded(item);
      Navigator.pop(context);
      _showSnackBar('Item added successfully!', Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _titleController,
                label: 'Title *',
                icon: Icons.title,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description *',
                icon: Icons.description,
                maxLines: 3,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Location *',
                icon: Icons.location_on,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildStatusDropdown(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Contact Email (Optional)',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v != null && v.isNotEmpty && 
                      !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Contact Phone (Optional)',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Item Photo (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildImageSection(),
                    const SizedBox(height: 8),
                    Text('Supports: JPG, PNG, GIF', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Add Item'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<ItemCategory>(
      initialValue: _category,
      decoration: const InputDecoration(
        labelText: 'Category *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: ItemCategory.values.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category.displayName),
        );
      }).toList(),
      onChanged: (value) => setState(() => _category = value!),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<LostItemStatus>(
      initialValue: _status,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.info),
      ),
      items: const [
        DropdownMenuItem(value: LostItemStatus.lost, child: Text('Lost')),
        DropdownMenuItem(value: LostItemStatus.found, child: Text('Found')),
      ],
      onChanged: (value) => setState(() => _status = value!),
    );
  }
}