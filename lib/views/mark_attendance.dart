import 'package:flutter/material.dart';

class MarkAttendance extends StatefulWidget {
  const MarkAttendance({
    super.key,
    required this.lectureId,
  });

  final String lectureId;

  @override
  State<MarkAttendance> createState() => _MarkAttendanceState();
}

class _MarkAttendanceState extends State<MarkAttendance> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
