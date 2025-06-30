import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sabaq/providers/student_provider.dart';
import 'package:marquee/marquee.dart';

import 'package:sabaq/models/student.dart';

class StudentDetailsScreen extends StatefulWidget {
  final Student student;

  const StudentDetailsScreen({super.key, required this.student});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  late Student _student;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 24,
          child: Marquee(
            text: 'Student Details',
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
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _student.imagePath != null
                      ? FileImage(File(_student.imagePath!))
                      : null,
                  child: _student.imagePath == null
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Name', _student.name, theme),
                      const Divider(),
                      _buildDetailRow(
                          'Father\'s Name', _student.fatherName, theme),
                      const Divider(),
                      InkWell(
                        onTap: () => _student.phoneNumber != null
                            ? _launchWhatsApp(
                                _student.phoneNumber!, context)
                            : null,
                        child: _buildEditableDetailRow(
                          'Phone Number',
                          _student.phoneNumber ?? 'Not set',
                          theme,
                          'phoneNumber',
                          isLink: _student.phoneNumber != null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
      String label, String currentValue, String field) async {
    final TextEditingController controller =
        TextEditingController(text: currentValue == 'Not set' ? '' : currentValue);
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter new $label'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newValue != null && newValue.trim().isNotEmpty) {
      setState(() {
        if (field == 'studentId') {
          _student = Student(
              id: _student.id,
              name: _student.name,
              fatherName: _student.fatherName,
              studentId: newValue,
              phoneNumber: _student.phoneNumber,
              imagePath: _student.imagePath,
              sectionId: _student.sectionId);
        } else if (field == 'phoneNumber') {
          _student = Student(
              id: _student.id,
              name: _student.name,
              fatherName: _student.fatherName,
              studentId: _student.studentId,
              phoneNumber: newValue,
              imagePath: _student.imagePath,
              sectionId: _student.sectionId);
        }
      });
      await context.read<StudentProvider>().updateStudent(_student);
    }
  }

  Widget _buildEditableDetailRow(
      String label, String value, ThemeData theme, String field,
      {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.titleMedium),
          Row(
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isLink ? Colors.blue : null,
                  decoration: isLink ? TextDecoration.underline : null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditDialog(label, value, field),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _launchWhatsApp(String phoneNumber, BuildContext context) async {
    final Uri whatsappUrl = Uri.parse('https://wa.me/$phoneNumber');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.titleMedium),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isLink ? Colors.blue : null,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }
}
