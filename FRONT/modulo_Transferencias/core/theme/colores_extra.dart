import 'package:flutter/material.dart';

@immutable
class ColoresExtra extends ThemeExtension<ColoresExtra> {
  final Color verdeIntenso;
  final Color verdeClaro;
  final Color disabled;

  const ColoresExtra({
    required this.verdeIntenso,
    required this.verdeClaro,
    required this.disabled,
  });

  @override
  ColoresExtra copyWith({
    Color? verdeIntenso,
    Color? verdeClaro,
    Color? disabled,
  }) {
    return ColoresExtra(
      verdeIntenso: verdeIntenso ?? this.verdeIntenso,
      verdeClaro: verdeClaro ?? this.verdeClaro,
      disabled: disabled ?? this.disabled,
    );
  }

  @override
  ColoresExtra lerp(ThemeExtension<ColoresExtra>? other, double t) {
    if (other is! ColoresExtra) return this;
    return ColoresExtra(
      verdeIntenso: Color.lerp(verdeIntenso, other.verdeIntenso, t)!,
      verdeClaro: Color.lerp(verdeClaro, other.verdeClaro, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
    );
  }
}