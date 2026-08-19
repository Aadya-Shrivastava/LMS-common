import '../models/user_model.dart';

/// Handles logging a user in.
///
/// There is no real backend yetp-=[], so `login()` just waits a moment
/// (to feel like a real network call) and then returns a fake user.
/// Later, once there's a real API, we can change the inside of this
/// method to call `ApiClient` instead, and nothing else in the app
/// will need to change.
class AuthService {
  Future<UserModel> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    // Pretend this takes a second, like a real network call would.
    await Future.delayed(const Duration(seconds: 1));

    if (role == UserRole.faculty) {
      return UserModel(
        id: 'faculty-001',
        name: 'Dr. Mahika Mishra',
        email: email,
        role: UserRole.faculty,
        designation: 'Assistant Professor',
        department: 'Computer Science Department',
      );
    }

    return UserModel(
      id: 'student-001',
      name: 'Rahul Verma',
      email: email,
      role: UserRole.student,
      department: 'Electrician',
      designation: 'Batch A · Semester 2',
    );
  }
}
