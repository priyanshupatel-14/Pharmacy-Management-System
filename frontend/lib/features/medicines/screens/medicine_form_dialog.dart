import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../../../core/theme/app_theme.dart';

class MedicineFormDialog extends StatefulWidget {
  final Medicine? medicine;

  const MedicineFormDialog({super.key, this.medicine});

  @override
  State<MedicineFormDialog> createState() => _MedicineFormDialogState();
}

class _MedicineFormDialogState extends State<MedicineFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _manufacturerController;
  late TextEditingController _unitPriceController;
  
  int? _selectedSupplierId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medicine?.name ?? '');
    _categoryController = TextEditingController(text: widget.medicine?.category ?? '');
    _manufacturerController = TextEditingController(text: widget.medicine?.manufacturer ?? '');
    _unitPriceController = TextEditingController(text: widget.medicine?.unitPrice.toString() ?? '');
    _selectedSupplierId = widget.medicine?.supplierId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _manufacturerController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<MedicineProvider>();
      
      final med = Medicine(
        id: widget.medicine?.id ?? 0,
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        manufacturer: _manufacturerController.text.trim(),
        unitPrice: double.parse(_unitPriceController.text.trim()),
        supplierId: _selectedSupplierId,
      );

      bool success;
      if (widget.medicine == null) {
        success = await provider.addMedicine(med);
      } else {
        success = await provider.updateMedicine(med);
      }

      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicineProvider>();
    final isEditing = widget.medicine != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Medicine' : 'Add New Medicine'),
      titlePadding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
      actionsPadding: const EdgeInsets.all(32),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medicine Details',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name *',
                    hintText: 'e.g. Amoxicillin 500mg',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Medicine name is required' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          hintText: 'e.g. Antibiotic',
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Category is required' : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextFormField(
                        controller: _unitPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Unit Price (₹) *',
                          prefixText: '₹ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          final parsed = double.tryParse(value);
                          if (parsed == null || parsed < 0) return 'Valid positive number required';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Supply Chain',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer',
                    hintText: 'e.g. Pfizer',
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(labelText: 'Primary Supplier'),
                  initialValue: _selectedSupplierId,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('None / Select Supplier'),
                    ),
                    ...provider.suppliers.map((s) {
                      return DropdownMenuItem<int?>(
                        value: s.id,
                        child: Text(s.name),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedSupplierId = val;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEditing ? 'Save Changes' : 'Add Medicine'),
        ),
      ],
    );
  }
}
