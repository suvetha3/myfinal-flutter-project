import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RequiredField extends StatelessWidget {
  final String label;

  const RequiredField(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
        children:  [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Theme.of(context).colorScheme.error,),
          ),
        ],
      ),
    );
  }
}

//spacer

class FormSpacer extends StatelessWidget {
  const FormSpacer({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(height: 10);
}

//button


class ReusableButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const ReusableButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      ),
      child: Text(label),
    );
  }
}

//date-picker


class ReusableDatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final void Function(DateTime picked) onDatePicked;
  final String? Function(String?)? validator;

  const ReusableDatePickerField({
    super.key,
    required this.controller,
    required this.label,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDatePicked,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(Icons.calendar_today,color: Theme.of(context).colorScheme.primary,),
        border: const OutlineInputBorder(),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) {
          controller.text = DateFormat('dd-MM-yyyy').format(picked);
          onDatePicked(picked);
        }
      },
    );
  }
}

//dropdown


class ReusableDropdown<T> extends StatelessWidget {
  final Widget label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const ReusableDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        label: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

//textfield


class ReusableTextField extends StatelessWidget {
  final TextEditingController controller;
  final Widget label;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool obscureText;
  final Widget? suffixIcon;

  const ReusableTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      obscureText: obscureText,
      decoration: InputDecoration(
        label: label,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
