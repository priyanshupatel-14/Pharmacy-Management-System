import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine_batch.dart';
import '../providers/batch_provider.dart';

class BatchFormDialog extends StatefulWidget {
  final MedicineBatch? batch;

  const BatchFormDialog({super.key, this.batch});

  @override
  State<BatchFormDialog> createState() => _BatchFormDialogState();
}

class _BatchFormDialogState extends State<BatchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _batchNumberController;
  late TextEditingController _expiryDateController;
  late TextEditingController _quantityController;
  late TextEditingController _purchasePriceController;
  
  int? _selectedMedicineId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _batchNumberController = TextEditingController(text: widget.batch?.batchNumber ?? '');
    _expiryDateController = TextEditingController(text: widget.batch?.expiryDate ?? '');
    _quantityController = TextEditingController(text: widget.batch?.quantity.toString() ?? '');
    _purchasePriceController = TextEditingController(text: widget.batch?.purchasePrice.toString() ?? '');
    _selectedMedicineId = widget.batch?.medicineId;
  }

  @override
  void dispose() {
    _batchNumberController.dispose();
    _expiryDateController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final initialDate = widget.batch != null 
        ? DateTime.tryParse(widget.batch!.expiryDate) ?? DateTime.now() 
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _expiryDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMedicineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a medicine'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<BatchProvider>();
      
      final batch = MedicineBatch(
        id: widget.batch?.id ?? 0,
        medicineId: _selectedMedicineId!,
        batchNumber: _batchNumberController.text.trim(),
        expiryDate: _expiryDateController.text.trim(),
        quantity: int.parse(_quantityController.text.trim()),
        purchasePrice: double.parse(_purchasePriceController.text.trim()),
      );

      bool success;
      if (widget.batch == null) {
        success = await provider.addBatch(batch);
      } else {
        success = await provider.updateBatch(batch);
      }

      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BatchProvider>();
    final isEditing = widget.batch != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Batch' : 'Add Batch'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(labelText: 'Medicine *'),
                  initialValue: _selectedMedicineId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Select a Medicine'),
                    ),
                    ...provider.medicines.map((m) {
                      return DropdownMenuItem<int?>(
                        value: m.id,
                        child: Text(m.name),
                      );
                    }),
                  ],
                  onChanged: isEditing ? null : (val) {
                    setState(() {
                      _selectedMedicineId = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _batchNumberController,
                  decoration: const InputDecoration(labelText: 'Batch Number *'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _expiryDateController,
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date (YYYY-MM-DD) *',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity *'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    final parsed = int.tryParse(value);
                    if (parsed == null || parsed < 0) return 'Valid positive integer required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _purchasePriceController,
                  decoration: const InputDecoration(labelText: 'Purchase Price *'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed < 0) return 'Valid positive number required';
                    return null;
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
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
