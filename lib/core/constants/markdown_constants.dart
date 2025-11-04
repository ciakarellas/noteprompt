/// Markdown syntax templates and constants
class MarkdownConstants {
  // Private constructor to prevent instantiation
  MarkdownConstants._();

  // Markdown Syntax
  static const String bold = '**';
  static const String italic = '*';
  static const String strikethrough = '~~';
  static const String inlineCode = '`';
  static const String codeBlock = '```';

  // Headers
  static const String h1 = '# ';
  static const String h2 = '## ';
  static const String h3 = '### ';
  static const String h4 = '#### ';
  static const String h5 = '##### ';
  static const String h6 = '###### ';

  // Lists
  static const String unorderedList = '- ';
  static const String orderedList = '1. ';

  // Other Elements
  static const String blockquote = '> ';
  static const String horizontalRule = '---';

  // Link Template
  static const String linkTemplate = '[text](url)';
  static const String linkPrefix = '[';
  static const String linkMiddle = '](';
  static const String linkSuffix = ')';

  // Image Template
  static const String imageTemplate = '![alt](url)';
  static const String imagePrefix = '![';
  static const String imageMiddle = '](';
  static const String imageSuffix = ')';

  // Placeholders
  static const String placeholder = 'placeholder';
  static const String linkTextPlaceholder = 'text';
  static const String linkUrlPlaceholder = 'url';
  static const String imageAltPlaceholder = 'alt';
  static const String imageUrlPlaceholder = 'url';
}
