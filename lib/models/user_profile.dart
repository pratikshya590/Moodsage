class UserProfile {
  final String uid;
  final String email;
  final String? name;
  final String? photoUrl;
  final bool hasPin;

  const UserProfile({
    required this.uid,
    required this.email,
    this.name,
    this.photoUrl,
    this.hasPin = false,
  });

  // Turns the JSON from the backend into a UserProfile
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: (json['email'] ?? '') as String,
      name: json['name'] as String?,
      photoUrl: json['photoUrl'] as String?,
      hasPin: json['hasPin'] == true,
    );
  }
}