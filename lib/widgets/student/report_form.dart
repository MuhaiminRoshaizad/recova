import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_constants.dart';
import '../../providers/report_provider.dart';
import '../../services/storage_service.dart';
import '../common/custom_text_field.dart';
import '../common/custom_button.dart';
import '../common/image_picker_widget.dart';

class ReportForm extends StatefulWidget {
  final ReportType type;
  const ReportForm({super.key, required this.type});

  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _categoryId;
  String? _location;
  DateTime? _date;
  File? _image;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _location == null || _date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _submitting = true);
    String? imageUrl;
    if (_image != null) {
      try {
        imageUrl = await StorageService().uploadReportImage(_image!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed: $e')),
          );
        }
      }
    }

    if (!mounted) return;
    final success = await context.read<ReportProvider>().createReport(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: widget.type.name,
      categoryId: _categoryId!,
      location: _location!,
      dateOccurred: _date!,
      imageUrl: imageUrl,
    );

    setState(() => _submitting = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted! Pending approval.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ReportProvider>().categories;
    final isLost = widget.type == ReportType.lost;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            isLost ? 'What did you lose?' : 'What did you find?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _titleCtrl,
            label: 'Item title',
            hint: isLost ? 'e.g. Black iPhone 15 Pro' : 'e.g. Blue water bottle',
            prefixIcon: Icons.title,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _descCtrl,
            label: 'Description',
            hint: 'Describe the item in detail...',
            maxLines: 4,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Text('Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _categoryId,
            decoration: const InputDecoration(hintText: 'Select category'),
            items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() => _categoryId = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Text('Location', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _location,
            decoration: InputDecoration(hintText: isLost ? 'Where did you last see it?' : 'Where did you find it?'),
            items: AppConstants.campusLocations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (v) => setState(() => _location = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Text('Date', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today)),
              child: Text(
                _date != null
                    ? '${_date!.day}/${_date!.month}/${_date!.year}'
                    : isLost ? 'When did you lose it?' : 'When did you find it?',
                style: TextStyle(color: _date != null ? null : Theme.of(context).hintColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Photo', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          ImagePickerWidget(imageFile: _image, onImagePicked: (f) => setState(() => _image = f)),
          const SizedBox(height: 24),
          CustomButton(text: 'Submit Report', onPressed: _submit, isLoading: _submitting),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
