// ─────────────────────────────────────────────
// lib/blocs/contact/contact_event.dart
// ─────────────────────────────────────────────
part of 'contact_bloc.dart';

abstract class ContactEvent extends Equatable {
  const ContactEvent();
  @override List<Object?> get props => [];
}

class FetchContacts extends ContactEvent {}

class SearchContacts extends ContactEvent {
  final String query;
  const SearchContacts(this.query);
  @override List<Object?> get props => [query];
}

class ToggleFavorite extends ContactEvent {
  final String walletNumber;
  const ToggleFavorite(this.walletNumber);
  @override List<Object?> get props => [walletNumber];
}