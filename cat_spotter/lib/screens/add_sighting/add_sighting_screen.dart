import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/cat_profile.dart';
import '../../providers/add_sighting_provider.dart';
import 'step1_camera.dart';
import 'step2_assign_cat.dart';
import 'step3_map_finetune.dart';

class AddSightingScreen extends ConsumerStatefulWidget {
  /// Pre-select a cat when navigating from Cat Detail.
  final CatProfile? preselectedCat;

  const AddSightingScreen({super.key, this.preselectedCat});

  @override
  ConsumerState<AddSightingScreen> createState() => _AddSightingScreenState();
}

class _AddSightingScreenState extends ConsumerState<AddSightingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // If a cat is pre-selected, set it in state.
    if (widget.preselectedCat != null) {
      Future.microtask(() {
        ref
            .read(addSightingProvider.notifier)
            .setSelectedCat(widget.preselectedCat!);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const stepLabels = ['Photo', 'Cat', 'Location'];

    return PopScope(
      // On step 0 allow normal pop; on later steps intercept and go back a step.
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _prevStep();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _prevStep),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final active = i == _currentStep;
              final done = i < _currentStep;
              return Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: active || done
                        ? AppColors.accent
                        : AppColors.surface,
                    child: done
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  if (i < 2) ...[
                    const SizedBox(width: 4),
                    Text(
                      stepLabels[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: active ? AppColors.accent : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 20,
                      height: 2,
                      color: done ? AppColors.accent : AppColors.divider,
                    ),
                    const SizedBox(width: 4),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        stepLabels[i],
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              active ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
          centerTitle: true,
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Step1Camera(onNext: _nextStep),
            Step2AssignCat(onNext: _nextStep),
            Step3MapFinetune(
              onSaved: () {
                ref.read(addSightingProvider.notifier).reset();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
