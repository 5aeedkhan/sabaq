import 'package:flutter/material.dart';
import 'dart:io';

import 'package:sabaq/models/student.dart'; // Import for File

class StudentDetailsScreen extends StatelessWidget {
  final Student student;

  const StudentDetailsScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Center column content
          children: [
            // Student Image Section
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle, // Circular image
                color:
                    theme
                        .colorScheme
                        .primaryContainer, // Placeholder background
                image:
                    student.imagePath != null &&
                            File(student.imagePath!).existsSync()
                        ? DecorationImage(
                          image: FileImage(File(student.imagePath!)),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  student.imagePath != null &&
                          File(student.imagePath!).existsSync()
                      ? null // Image is displayed by DecorationImage
                      : Icon(
                        Icons.person,
                        size: 60,
                        color: theme.colorScheme.onPrimaryContainer,
                      ), // Placeholder icon
            ),
            const SizedBox(height: 16),
            // Student Name
            Text(
              student.name,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onBackground, // Use theme color
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 24),

            // Personal Information Card
            _buildDetailCard(
              context: context,
              title: 'Personal Information',
              children: [
                _buildDetailRow('Father\'s Name', student.fatherName, theme),
                _buildDetailRow('Age', student.age.toString(), theme),
              ],
            ),
            const SizedBox(height: 16),
            // Academic Information Card
            _buildDetailCard(
              context: context,
              title: 'Academic Information',
              children: [
                _buildDetailRow('Student ID', student.studentId, theme),
                _buildDetailRow('Darja', student.darja, theme),
              ],
            ),
            const SizedBox(height: 16),
            // Contact Information Card
            _buildDetailCard(
              context: context,
              title: 'Contact Information',
              children: [
                _buildDetailRow('Phone Number', student.phoneNumber, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
      ), // Add horizontal margin
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ), // Use theme text style
            ),
            const Divider(
              height: 20,
              thickness: 1.5,
            ), // Add space and thickness
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(
                  0.7,
                ), // Use theme color with opacity
              ), // Use theme text style
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
              ), // Use theme text style
            ),
          ),
        ],
      ),
    );
  }
}
