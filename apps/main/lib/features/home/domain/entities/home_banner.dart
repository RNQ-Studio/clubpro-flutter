/// Satu slide banner di Beranda (dari back-office, atau bawaan app).
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.linkUrl,
  });

  factory HomeBanner.fromJson(Map<String, dynamic> json) => HomeBanner(
        id: json['id'].toString(),
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        imageUrl: json['image_url'] as String?,
        linkUrl: json['link_url'] as String?,
      );

  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;

  /// URL https (dibuka di browser) atau rute app yang diawali `/`.
  final String? linkUrl;
}
