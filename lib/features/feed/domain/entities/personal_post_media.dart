class PersonalPostMedia {
  const PersonalPostMedia({
    required this.localPath,
    required this.byteSize,
    required this.isVideo,
  });

  final String localPath;
  final int byteSize;
  final bool isVideo;
}
