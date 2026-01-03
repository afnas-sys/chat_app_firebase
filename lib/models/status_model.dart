class Status {
  final String uid;
  final String username;
  final String phoneNumber; // useful to match contacts
  final String profilePic;
  final String statusId;
  // Let's make "Status" represent a SINGLE story item.
  // When we fetch, we group them.
  final String imageUrl;
  final String caption;
  final DateTime timestamp;
  final DateTime expiresAt;
  final List<Map<String, dynamic>>
  viewers; // List of {uid: String, timestamp: int}

  Status({
    required this.uid,
    required this.username,
    required this.phoneNumber,
    required this.profilePic,
    required this.statusId,
    required this.imageUrl,
    required this.caption,
    required this.timestamp,
    required this.expiresAt,
    required this.viewers,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'phoneNumber': phoneNumber,
      'profilePic': profilePic,
      'statusId': statusId,
      'imageUrl': imageUrl,
      'caption': caption,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'viewers': viewers,
    };
  }

  factory Status.fromMap(Map<String, dynamic> map) {
    var rawViewers = map['viewers'];
    List<Map<String, dynamic>> viewersList = [];
    if (rawViewers is List) {
      for (var v in rawViewers) {
        if (v is String) {
          viewersList.add({'uid': v, 'timestamp': null});
        } else if (v is Map) {
          viewersList.add(Map<String, dynamic>.from(v));
        }
      }
    }

    return Status(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePic: map['profilePic'] ?? '',
      statusId: map['statusId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt']),
      viewers: viewersList,
    );
  }
}
