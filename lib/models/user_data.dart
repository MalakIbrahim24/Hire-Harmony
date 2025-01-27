class UserData {
  final String id;
  final String name;
  final String email;
  final String password;
  final String photoUrl;
  
  

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.photoUrl,
  });

  // Convert a Firestore document to a UserData object
  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      id: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      photoUrl: map['img'] ?? 'https://t3.ftcdn.net/jpg/02/43/12/34/360_F_243123463_zTooub557xEWABDLk0jJklDyLSGl2jrr.jpg',
    );
  }
  

  // Convert a UserData object to a Map
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    result.addAll({'id': id});
    result.addAll({'name': name});
    result.addAll({'email': email});
    result.addAll({'password': password});
    result.addAll({'PhotoUrl': photoUrl});
    return result;
  }
}
