import 'package:flutter/material.dart';

class CfgRadioListTile<T> extends StatelessWidget {

  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final String title;
  final Icon? icon;
  final String? leading;
  final bool dense;

  const CfgRadioListTile({
    Key? key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    this.icon,
    this.leading,
    this.dense = false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    List<Widget> widgetsRow = [];
    if(icon != null) {
      widgetsRow.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: icon));
      widgetsRow.add(SizedBox(width: dense ? 16 : 24));
    }
    if(leading != null) {
      widgetsRow.add(_customRadioButton);
      widgetsRow.add(SizedBox(width: dense ? 24 : 32));
    }
    widgetsRow.add(Text(title, style: Theme.of(context).primaryTextTheme.titleSmall));

    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
          color: value == groupValue ? Colors.brown[100] : Colors.white24,
          padding: EdgeInsets.all(dense ? 8 : 16),
          child: Row(children: widgetsRow)),
    );
  }

  Widget get _customRadioButton {
    final isSelected = value == groupValue;
    return Container(
      width: dense ? 42 : 54,
      padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 16, vertical: dense ? 6 : 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.amber : null,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? Colors.amber : Colors.brown,
        ),
      ),
      child: Text(
        leading!,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.brown,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}