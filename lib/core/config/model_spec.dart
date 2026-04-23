class ModelSpec {
  const ModelSpec({
    required this.label,
    required this.filename,
    required this.url,
    this.sha256 = '',
    this.usePlaceholder = false,
  });

  final String label;
  final String filename;
  final String url;
  final String sha256;
  final bool usePlaceholder;
}
