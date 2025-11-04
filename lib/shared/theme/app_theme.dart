import 'package:flutter/material.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // Markdown Style Sheet for Light Theme
  static MarkdownStyleSheet markdownStyleLight(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownStyleSheet(
      h1: theme.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      h2: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      h3: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      p: theme.textTheme.bodyLarge,
      code: theme.textTheme.bodyMedium?.copyWith(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      blockquote: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
    );
  }

  // Markdown Style Sheet for Dark Theme
  static MarkdownStyleSheet markdownStyleDark(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownStyleSheet(
      h1: theme.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      h2: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      h3: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      p: theme.textTheme.bodyLarge,
      code: theme.textTheme.bodyMedium?.copyWith(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      blockquote: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
    );
  }
}
