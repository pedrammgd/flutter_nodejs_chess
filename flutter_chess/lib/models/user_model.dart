class UserModel {
  final String id;
  final String username;
  final String email;
  final String avatar;
  final int    rating;
  final int    wins;
  final int    losses;
  final int    draws;
  final bool   isOnline;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatar  = '',
    this.rating  = 1200,
    this.wins    = 0,
    this.losses  = 0,
    this.draws   = 0,
    this.isOnline = false,
  });

  int get totalGames => wins + losses + draws;

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:       j['_id']      ?? '',
    username: j['username'] ?? '',
    email:    j['email']    ?? '',
    avatar:   j['avatar']   ?? '',
    rating:   j['rating']   ?? 1200,
    wins:     j['wins']     ?? 0,
    losses:   j['losses']   ?? 0,
    draws:    j['draws']    ?? 0,
    isOnline: j['isOnline'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    '_id': id, 'username': username, 'email': email,
    'avatar': avatar, 'rating': rating,
    'wins': wins, 'losses': losses, 'draws': draws,
  };
}
