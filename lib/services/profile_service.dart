import '../models/user_profile.dart';
import 'api_service.dart';

class ProfileService {
  ProfileService._();
  static final instance = ProfileService._();

  /// Called right after sign up: creates the profile in Firestore
  Future<UserProfile> createProfile() async {
    final data = await ApiService.instance.post('/profile');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  /// Gets the logged-in user's profile (name, hasPin...)
  Future<UserProfile> getProfile() async {
    final data = await ApiService.instance.get('/profile');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  /// Saves the name and (optional) photo through the backend
  Future<UserProfile> updateProfile({
    required String name,
    String? photoDataUrl,
  }) async {
    final data = await ApiService.instance.put('/profile', {
      'name': name,
      if (photoDataUrl != null) 'photoUrl': photoDataUrl,
    });
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }
}
