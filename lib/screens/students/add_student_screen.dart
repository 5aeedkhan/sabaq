import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sabaq/models/student.dart';
import 'package:sabaq/providers/student_provider.dart';
import '../../viewmodels/add_student_viewmodel.dart';
import 'package:marquee/marquee.dart';

class AddStudentScreen extends StatefulWidget {
  final int sectionId;
  const AddStudentScreen({super.key, required this.sectionId});

  @override
  _AddStudentScreenState createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late AddStudentViewModel _viewModel;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _viewModel = AddStudentViewModel();
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from Gallery'),
              onTap: () {
                _getImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Picture'),
              onTap: () {
                _getImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _viewModel.selectedImage = File(pickedFile.path);
        _viewModel.imagePath = pickedFile.path;
      });
    }
  }

  void _saveStudent() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newStudent = Student(
        name: _viewModel.name,
        fatherName: _viewModel.fatherName,
        studentId: _viewModel.studentId,
        phoneNumber: _viewModel.phoneNumber,
        imagePath: _viewModel.imagePath,
        sectionId: widget.sectionId,
      );
      context.read<StudentProvider>().addStudent(newStudent).then((_) {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 24,
          child: Marquee(
            text: 'Add New Student',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            blankSpace: 40.0,
            velocity: 30.0,
            pauseAfterRound: Duration(seconds: 1),
            startPadding: 10.0,
            accelerationDuration: Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  backgroundImage: _viewModel.selectedImage != null
                      ? FileImage(_viewModel.selectedImage!)
                      : null,
                  child: _viewModel.selectedImage == null
                      ? Icon(
                          Icons.camera_alt,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 40,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to change picture',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 32),
              _buildTextField(
                label: 'Name',
                icon: Icons.person,
                onSaved: (value) => _viewModel.name = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Father\'s Name',
                icon: Icons.group,
                onSaved: (value) => _viewModel.fatherName = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a father\'s name' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                onSaved: (value) => _viewModel.phoneNumber = value!,
                validator: (value) => null,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _saveStudent,
                icon: const Icon(Icons.save),
                label: const Text('Save Student'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: keyboardType,
      onSaved: onSaved,
      validator: validator,
    );
  }
}
