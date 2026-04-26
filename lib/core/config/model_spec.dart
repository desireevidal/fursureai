class ModelSpec {
  const ModelSpec({
    required this.label,
    required this.filename,
    required this.url,
    this.assetPath = '',
    this.sha256 = '',
    this.usePlaceholder = false,
  });

  final String label;
  final String filename;
  final String url;
  final String assetPath;
  final String sha256;
  final bool usePlaceholder;
}
