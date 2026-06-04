List<String> extractUploadedImageUrls(Object? data) {
  final urls = <String>[];

  void addUrl(Object? value) {
    if (value is! String) {
      return;
    }

    final trimmed = value.trim();
    if (trimmed.isNotEmpty && !urls.contains(trimmed)) {
      urls.add(trimmed);
    }
  }

  void parseImage(Object? image) {
    if (image is String) {
      addUrl(image);
      return;
    }

    if (image is Map) {
      addUrl(image['url']);
      addUrl(image['secure_url']);
      addUrl(image['secureUrl']);
      addUrl(image['imageUrl']);
    }
  }

  void parseContainer(Object? value) {
    if (value is List) {
      for (final item in value) {
        parseImage(item);
      }
      return;
    }

    if (value is! Map) {
      return;
    }

    parseContainer(value['data']);
    parseContainer(value['images']);
    parseContainer(value['urls']);
    parseContainer(value['imageUrls']);
    parseImage(value);
  }

  parseContainer(data);
  return urls;
}
