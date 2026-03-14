import 'package:flutter/material.dart';
import 'package:segment_display/segment_display.dart';

void main() {
  SevenSegmentDisplay(
    value: "12:34",
    size: 12.0,
    characterCount: 5,
    backgroundColor: Colors.transparent,
    segmentStyle: HexSegmentStyle(
      enabledColor: Colors.red,
      disabledColor: const Color(0xFF101010),
    ),
  );
}
