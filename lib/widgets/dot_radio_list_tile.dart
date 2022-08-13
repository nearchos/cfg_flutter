import 'package:flutter/material.dart';

class DotRadioListTile<T> extends StatelessWidget {

  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final String title;
  final IconData? iconData;
  final bool dense;
  final bool alwaysShowLeadingIcon;

  const DotRadioListTile({
    Key? key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    this.iconData,
    this.dense = true,
    this.alwaysShowLeadingIcon = false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return ListTile(
      title: Text(title, style: isSelected ? const TextStyle(fontWeight: FontWeight.bold) : const TextStyle(fontWeight: FontWeight.normal)),
      leading: alwaysShowLeadingIcon || isSelected && iconData != null ? Icon(iconData, color: Colors.brown) : const SizedBox(),
      trailing: !isSelected ? const SizedBox() : SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Colors.brown,
                  shape: BoxShape.circle
              )
          ),
        ),
      ),
      dense: dense,
      onTap: () => onChanged(value),
    );
  }
}