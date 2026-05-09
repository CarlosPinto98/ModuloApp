import 'package:flutter/material.dart';
import 'colores.dart';
import 'colores_extra.dart';
import 'typography.dart';

final ThemeData temaClaro = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: temaClaroPrimary,
    onPrimary: temaClaroOnPrimary,
    secondary: temaClaroSecondary,
    onSecondary: temaClaroOnSecondary,
    tertiary: temaClaroTertiary,
    onTertiary: temaClaroOnTertiary,
    error: temaClaroError,
    onError: temaClaroOnError,
    surface: temaClaroSurface,
    onSurface: temaClaroOnSurface,
    onSurfaceVariant: temaClaroOnSurfaceVariant,
    outline: temaClaroOutline,
    inverseSurface: temaClaroInverseSurface,
    inversePrimary: temaClaroInversePrimary,
  ),
  textTheme: AppTypography.textTheme,
  extensions: const <ThemeExtension<dynamic>>[
    ColoresExtra(
      verdeIntenso: temaClaroVerdeIntenso,
      verdeClaro: temaClaroVerdeClaro,
      disabled: temaClaroDisabled,
    ),
  ],
);

final ThemeData temaOscuro = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: temaOscuroPrimary,
    onPrimary: temaOscuroOnPrimary,
    secondary: temaOscuroSecondary,
    onSecondary: temaOscuroOnSecondary,
    tertiary: temaOscuroTertiary,
    onTertiary: temaOscuroOnTertiary,
    error: temaOscuroError,
    onError: temaOscuroOnError,
    surface: temaOscuroSurface,
    onSurface: temaOscuroOnSurface,
    onSurfaceVariant: temaOscuroOnSurfaceVariant,
    outline: temaOscuroOutline,
    inverseSurface: temaOscuroInverseSurface,
    inversePrimary: temaOscuroInversePrimary,
  ),
  textTheme: AppTypography.textTheme,
  extensions: const <ThemeExtension<dynamic>>[
    ColoresExtra(
      verdeIntenso: temaOscuroVerdeIntenso,
      verdeClaro: temaOscuroVerdeClaro,
      disabled: temaOscuroDisabled,
    ),
  ],
);