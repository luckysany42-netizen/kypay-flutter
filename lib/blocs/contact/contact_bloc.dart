// ─────────────────────────────────────────────
// lib/blocs/contact/contact_bloc.dart
// ─────────────────────────────────────────────
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';

part 'contact_event.dart';
part 'contact_state.dart';

class ContactBloc extends Bloc<ContactEvent, ContactState> {
  ContactBloc() : super(ContactInitial()) {
    on<FetchContacts>(_onFetch);
    on<SearchContacts>(_onSearch);
    on<ToggleFavorite>(_onToggleFavorite);
  }

  Future<void> _onFetch(FetchContacts event, Emitter<ContactState> emit) async {
    emit(ContactLoading());
    try {
      final response = await ApiService.dio.get('/contacts');
      final List raw  = response.data['data'] ?? [];
      final contacts  = raw.map((e) => ContactModel.fromJson(e)).toList();
      emit(ContactLoaded(all: contacts, filtered: contacts));
    } catch (e) {
      emit(const ContactError('Gagal memuat kontak.'));
    }
  }

  void _onSearch(SearchContacts event, Emitter<ContactState> emit) {
    if (state is! ContactLoaded) return;
    final loaded = state as ContactLoaded;
    final q      = event.query.toLowerCase().trim();
    final filtered = q.isEmpty
        ? loaded.all
        : loaded.all.where((c) =>
            c.ownerName.toLowerCase().contains(q) ||
            c.walletNumber.toLowerCase().contains(q)).toList();
    emit(ContactLoaded(all: loaded.all, filtered: filtered, query: event.query));
  }

  Future<void> _onToggleFavorite(
      ToggleFavorite event, Emitter<ContactState> emit) async {
    if (state is! ContactLoaded) return;
    final loaded = state as ContactLoaded;

    // Optimistic update
    final updated = loaded.all.map((c) {
      if (c.walletNumber == event.walletNumber) {
        return c.copyWith(isFavorite: !c.isFavorite);
      }
      return c;
    }).toList();

    // Re-apply filter
    final q        = loaded.query.toLowerCase().trim();
    final filtered = q.isEmpty
        ? updated
        : updated.where((c) =>
            c.ownerName.toLowerCase().contains(q) ||
            c.walletNumber.toLowerCase().contains(q)).toList();

    emit(ContactLoaded(all: updated, filtered: filtered, query: loaded.query));

    // Call API (fire and forget — kalau gagal tidak apa-apa)
    try {
      await ApiService.dio.post('/contacts/${event.walletNumber}/favorite');
    } catch (_) {}
  }
}