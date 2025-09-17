class FileItem {
  final String name;
  final String url;
  final String type;
  final String loanNumber;
  final DateTime uploadDate;
  final int size;

  FileItem({
    required this.name,
    required this.url,
    required this.type,
    required this.loanNumber,
    required this.uploadDate,
    required this.size,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? '',
      loanNumber: json['loanNumber'] ?? '',
      uploadDate: DateTime.parse(json['uploadDate']),
      size: json['size'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'type': type,
      'loanNumber': loanNumber,
      'uploadDate': uploadDate.toIso8601String(),
      'size': size,
    };
  }

  bool get isImage => type.toLowerCase().contains('image') ||
                     name.toLowerCase().endsWith('.jpg') ||
                     name.toLowerCase().endsWith('.jpeg') ||
                     name.toLowerCase().endsWith('.png') ||
                     name.toLowerCase().endsWith('.gif');

  bool get isVideo => type.toLowerCase().contains('video') ||
                     name.toLowerCase().endsWith('.mp4') ||
                     name.toLowerCase().endsWith('.mov') ||
                     name.toLowerCase().endsWith('.avi');

  bool get isPdf => type.toLowerCase().contains('pdf') ||
                   name.toLowerCase().endsWith('.pdf');

  bool get isDocument => isPdf ||
                        name.toLowerCase().endsWith('.doc') ||
                        name.toLowerCase().endsWith('.docx') ||
                        name.toLowerCase().endsWith('.txt');
}