// ─────────────────────────────────────────────
// lib/blocs/contact/contact_state.dart
// ─────────────────────────────────────────────
part of 'contact_bloc.dart';

class ContactModel extends Equatable {
  final String walletNumber;
  final String walletName;
  final String ownerName;
  final String? ownerAvatar;
  final bool isFavorite;

  const ContactModel({
    required this.walletNumber,
    required this.walletName,
    required this.ownerName,
    this.ownerAvatar,
    this.isFavorite = false,
  });

  ContactModel copyWith({bool? isFavorite}) => ContactModel(
        walletNumber: walletNumber,
        walletName: walletName,
        ownerName: ownerName,
        ownerAvatar: ownerAvatar,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  factory ContactModel.fromJson(Map<String, dynamic> json) => ContactModel(
        walletNumber: json['wallet_number'] ?? '',
        walletName:   json['wallet_name'] ?? '',
        ownerName:    json['owner_name'] ?? '',
        ownerAvatar:  json['owner_avatar'],
        isFavorite:   json['is_favorite'] == true,
      );

  @override
  List<Object?> get props =>
      [walletNumber, walletName, ownerName, ownerAvatar, isFavorite];
}

abstract class ContactState extends Equatable {
  const ContactState();
  @override List<Object?> get props => [];
}

class ContactInitial  extends ContactState {}
class ContactLoading  extends ContactState {}

class ContactLoaded extends ContactState {
  final List<ContactModel> all;       // semua kontak
  final List<ContactModel> filtered;  // hasil search
  final String query;

  const ContactLoaded({
    required this.all,
    required this.filtered,
    this.query = '',
  });

  List<ContactModel> get favorites =>
      all.where((c) => c.isFavorite).toList();

  @override
  List<Object?> get props => [all, filtered, query];
}

class ContactError extends ContactState {
  final String message;
  const ContactError(this.message);
  @override List<Object?> get props => [message];
}