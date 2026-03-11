import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cat_profile.dart';

class AddSightingState {
  final XFile? capturedImage;
  final Position? gpsPosition;
  final bool gpsLoading;
  final CatProfile? selectedCat;
  final String notes;

  const AddSightingState({
    this.capturedImage,
    this.gpsPosition,
    this.gpsLoading = false,
    this.selectedCat,
    this.notes = '',
  });

  bool get hasImage => capturedImage != null;
  bool get hasCat => selectedCat != null;

  AddSightingState copyWith({
    XFile? capturedImage,
    Position? gpsPosition,
    bool clearGps = false,
    bool? gpsLoading,
    CatProfile? selectedCat,
    String? notes,
  }) =>
      AddSightingState(
        capturedImage: capturedImage ?? this.capturedImage,
        gpsPosition: clearGps ? null : (gpsPosition ?? this.gpsPosition),
        gpsLoading: gpsLoading ?? this.gpsLoading,
        selectedCat: selectedCat ?? this.selectedCat,
        notes: notes ?? this.notes,
      );
}

class AddSightingNotifier extends StateNotifier<AddSightingState> {
  AddSightingNotifier() : super(const AddSightingState());

  void setImage(XFile image) => state = state.copyWith(capturedImage: image);

  void setGpsPosition(Position? position) =>
      state = state.copyWith(gpsPosition: position, gpsLoading: false);

  void setGpsLoading(bool loading) =>
      state = state.copyWith(gpsLoading: loading);

  void setSelectedCat(CatProfile cat) =>
      state = state.copyWith(selectedCat: cat);

  void setNotes(String notes) => state = state.copyWith(notes: notes);

  void reset() => state = const AddSightingState();
}

final addSightingProvider =
    StateNotifierProvider.autoDispose<AddSightingNotifier, AddSightingState>(
  (ref) => AddSightingNotifier(),
);
