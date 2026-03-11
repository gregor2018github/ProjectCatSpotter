import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/cat_profile.dart';
import '../../providers/cat_profiles_provider.dart';
import '../../services/camera_service.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/local_image.dart';

class CatFormScreen extends ConsumerStatefulWidget {
  /// Pass an existing profile to enter edit mode; null = add mode.
  final CatProfile? existing;

  /// Pre-populate the cover photo from a sighting image (used when creating a
  /// new cat from within the add-sighting flow). Only applied in create mode.
  final XFile? initialCoverFile;

  const CatFormScreen({super.key, this.existing, this.initialCoverFile});

  @override
  ConsumerState<CatFormScreen> createState() => _CatFormScreenState();
}

class _CatFormScreenState extends ConsumerState<CatFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  /// Relative path of the chosen cover image (persisted to disk).
  String? _coverImagePath;

  /// Sighting image not yet persisted — shown as preview until form save.
  /// Using the XFile directly avoids orphaned files if the user cancels.
  XFile? _pendingCoverFile;

  /// Previous cover path to delete if the user replaces the image.
  String? _previousCoverPath;

  int _selectedColor = CatProfile.defaultColor;
  bool _saving = false;

  static const List<int> _presetColors = [
    0xFFE53935, // Red
    0xFFD81B60, // Pink
    0xFF8E24AA, // Purple
    0xFF3949AB, // Indigo
    0xFF1E88E5, // Blue
    0xFF00ACC1, // Cyan
    0xFF00897B, // Teal
    0xFF43A047, // Green
    0xFFFFB300, // Amber
    0xFFFF8C42, // Orange (default accent)
    0xFFE64A19, // Deep Orange
    0xFF6D4C41, // Brown
  ];

  bool get _isEdit => widget.existing != null;
  bool get _hasCover => _coverImagePath != null || _pendingCoverFile != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _coverImagePath = e?.coverImagePath;
    _selectedColor = e?.color ?? CatProfile.defaultColor;

    // Pre-populate cover from the sighting photo when creating a new cat.
    if (!_isEdit && widget.initialCoverFile != null && _coverImagePath == null) {
      _pendingCoverFile = widget.initialCoverFile;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Cat' : 'New Cat'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              'Save',
              style: TextStyle(
                color: _saving ? AppColors.textSecondary : AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _coverPicker(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Cat's name *"),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),
            _colorPicker(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                counterText:
                    '${_notesController.text.length}/${AppConstants.notesMaxLength}',
              ),
              maxLines: 4,
              maxLength: AppConstants.notesMaxLength,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                  Text(
                '$currentLength/${maxLength ?? AppConstants.notesMaxLength}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 32),
              Center(
                child: TextButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  label: const Text(
                    'Delete Cat Profile',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Cover photo picker ─────────────────────────────────────────────────────

  Widget _coverPicker() {
    return GestureDetector(
      onTap: _pickCoverPhoto,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 2),
          color: AppColors.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_coverImagePath != null)
              LocalImage(relativePath: _coverImagePath, fit: BoxFit.cover)
            else if (_pendingCoverFile != null)
              Image.file(
                File(_pendingCoverFile!.path),
                fit: BoxFit.cover,
                width: double.infinity,
              )
            else
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo, color: AppColors.accent, size: 40),
                    SizedBox(height: 8),
                    Text('Add cover photo',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            if (_hasCover)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: () => setState(() {
                      _previousCoverPath = _coverImagePath;
                      _coverImagePath = null;
                      _pendingCoverFile = null;
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _pickCoverPhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.accent),
              title: const Text('Take photo'),
              onTap: () async {
                Navigator.pop(context);
                final file = await CameraService.takePhoto();
                if (file != null) {
                  final path =
                      await ImageStorageService.saveImage(file, isCover: true);
                  setState(() {
                    _previousCoverPath = _coverImagePath;
                    _coverImagePath = path;
                    _pendingCoverFile = null;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.accent),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                final file = await CameraService.pickFromGallery();
                if (file != null) {
                  final path =
                      await ImageStorageService.saveImage(file, isCover: true);
                  setState(() {
                    _previousCoverPath = _coverImagePath;
                    _coverImagePath = path;
                    _pendingCoverFile = null;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Colour picker ──────────────────────────────────────────────────────────

  Widget _colorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Map marker colour',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._presetColors.map((c) {
              final selected = _selectedColor == c;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.textPrimary
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Color(c).withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }),
            // Custom colour dot — opens the full colour wheel.
            _customColorDot(),
          ],
        ),
      ],
    );
  }

  Widget _customColorDot() {
    final isCustom = !_presetColors.contains(_selectedColor);
    return GestureDetector(
      onTap: _openColorWheel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          // Rainbow sweep gradient when no custom colour is active.
          gradient: isCustom
              ? null
              : const SweepGradient(
                  colors: [
                    Color(0xFFFF0000),
                    Color(0xFFFFFF00),
                    Color(0xFF00FF00),
                    Color(0xFF00FFFF),
                    Color(0xFF0000FF),
                    Color(0xFFFF00FF),
                    Color(0xFFFF0000),
                  ],
                ),
          color: isCustom ? Color(_selectedColor) : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: isCustom ? AppColors.textPrimary : Colors.grey.shade400,
            width: isCustom ? 3 : 1.5,
          ),
          boxShadow: isCustom
              ? [
                  BoxShadow(
                    color: Color(_selectedColor).withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isCustom
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : const Icon(Icons.palette, color: Colors.white, size: 18),
      ),
    );
  }

  Future<void> _openColorWheel() async {
    final result = await showDialog<Color>(
      context: context,
      builder: (_) => _ColorWheelDialog(initialColor: Color(_selectedColor)),
    );
    if (result != null && mounted) {
      setState(() => _selectedColor = result.toARGB32());
    }
  }

  // ── Save / Delete ──────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // If the user kept the pre-populated sighting image, persist it now.
    if (_pendingCoverFile != null) {
      _coverImagePath = await ImageStorageService.saveImage(
        _pendingCoverFile!,
        isCover: true,
      );
      _pendingCoverFile = null;
    }

    // Delete old cover image if it was replaced.
    if (_previousCoverPath != null && _previousCoverPath != _coverImagePath) {
      await ImageStorageService.deleteImage(_previousCoverPath);
    }

    final notifier = ref.read(catProfilesProvider.notifier);

    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        name: _nameController.text.trim(),
        coverImagePath: _coverImagePath,
        clearCoverImage: _coverImagePath == null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        clearNotes: _notesController.text.trim().isEmpty,
        color: _selectedColor,
      );
      await notifier.updateProfile(updated);
      if (mounted) Navigator.pop(context);
    } else {
      final profile = CatProfile(
        name: _nameController.text.trim(),
        coverImagePath: _coverImagePath,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        color: _selectedColor,
      );
      await notifier.addProfile(profile);
      if (mounted) Navigator.pop(context, profile);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete ${widget.existing!.name}?',
      message:
          'This will permanently delete this cat and all its sightings and photos.',
    );
    if (confirmed && mounted) {
      await ref
          .read(catProfilesProvider.notifier)
          .deleteProfile(widget.existing!.id,
              coverImagePath: widget.existing!.coverImagePath);
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Colour wheel dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ColorWheelDialog extends StatefulWidget {
  final Color initialColor;
  const _ColorWheelDialog({required this.initialColor});

  @override
  State<_ColorWheelDialog> createState() => _ColorWheelDialogState();
}

class _ColorWheelDialogState extends State<_ColorWheelDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
    // Grey/white colours have near-zero saturation; push them to a visible
    // position on the wheel so the dialog doesn't open at the centre.
    if (_hsv.saturation < 0.05) {
      _hsv = _hsv.withSaturation(0.8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _hsv.toColor();
    final useDarkText = _hsv.value > 0.6 && _hsv.saturation < 0.7;

    return AlertDialog(
      backgroundColor: AppColors.background,
      title: const Text('Pick a colour'),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Colour wheel ─────────────────────────────────────────────
            _ColorWheelWidget(
              hsv: _hsv,
              onChanged: (hsv) => setState(() => _hsv = hsv),
            ),
            const SizedBox(height: 12),

            // ── Brightness slider ─────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.brightness_low,
                    size: 18, color: AppColors.textSecondary),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbColor: selectedColor,
                      activeTrackColor:
                          _hsv.withSaturation(1.0).withValue(1.0).toColor(),
                      inactiveTrackColor: Colors.grey.shade300,
                      overlayColor: selectedColor.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _hsv.value,
                      onChanged: (v) =>
                          setState(() => _hsv = _hsv.withValue(v)),
                    ),
                  ),
                ),
                const Icon(Icons.brightness_high,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 10),

            // ── Colour preview bar ────────────────────────────────────────
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedColor,
            foregroundColor: useDarkText ? Colors.black87 : Colors.white,
          ),
          onPressed: () => Navigator.pop(context, selectedColor),
          child: const Text('Select'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Colour wheel widget (hue + saturation circle)
// ─────────────────────────────────────────────────────────────────────────────

class _ColorWheelWidget extends StatelessWidget {
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  static const double _kSize = 230.0;
  static const double _kRadius = _kSize / 2;

  const _ColorWheelWidget({required this.hsv, required this.onChanged});

  void _updateFromOffset(Offset local) {
    final dx = local.dx - _kRadius;
    final dy = local.dy - _kRadius;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist > _kRadius) return; // outside circle — ignore
    final hue = (math.atan2(dy, dx) * 180.0 / math.pi + 360.0) % 360.0;
    final sat = (dist / _kRadius).clamp(0.0, 1.0);
    onChanged(HSVColor.fromAHSV(hsv.alpha, hue, sat, hsv.value));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _updateFromOffset(d.localPosition),
      onPanUpdate: (d) => _updateFromOffset(d.localPosition),
      onTapDown: (d) => _updateFromOffset(d.localPosition),
      child: CustomPaint(
        painter: _WheelPainter(hsv),
        size: const Size(_kSize, _kSize),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Colour wheel painter
// ─────────────────────────────────────────────────────────────────────────────

class _WheelPainter extends CustomPainter {
  final HSVColor hsv;
  _WheelPainter(this.hsv);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Hue sweep: red → yellow → green → cyan → blue → magenta → red.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFFF0000), //   0° red
            Color(0xFFFFFF00), //  60° yellow
            Color(0xFF00FF00), // 120° green
            Color(0xFF00FFFF), // 180° cyan
            Color(0xFF0000FF), // 240° blue
            Color(0xFFFF00FF), // 300° magenta
            Color(0xFFFF0000), // 360° red (close the ring)
          ],
        ).createShader(rect),
    );

    // 2. Saturation: white at centre fading to transparent at the edge.
    //    Blending with the hue layer creates the full HSV saturation axis.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, Colors.white.withAlpha(0)],
        ).createShader(rect),
    );

    // 3. Value/brightness: uniform black overlay (opacity = 1 − value).
    if (hsv.value < 1.0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.black.withAlpha(((1.0 - hsv.value) * 200).round()),
      );
    }

    // 4. Selection indicator dot.
    final hueRad = hsv.hue * math.pi / 180.0;
    final satR = hsv.saturation * radius;
    final dot = Offset(
      center.dx + satR * math.cos(hueRad),
      center.dy + satR * math.sin(hueRad),
    );

    // White ring + grey stroke for contrast against any background.
    canvas.drawCircle(dot, 11, Paint()..color = Colors.white);
    canvas.drawCircle(
      dot,
      11,
      Paint()
        ..color = Colors.black45
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Inner dot showing the hue/saturation at full brightness.
    canvas.drawCircle(
      dot,
      8,
      Paint()
        ..color =
            HSVColor.fromAHSV(1.0, hsv.hue, hsv.saturation, 1.0).toColor(),
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.hsv != hsv;
}
