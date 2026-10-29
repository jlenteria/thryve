import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_store.dart';
import 'onboarding_view_model.dart';
import 'widgets/step_notifications.dart';
import 'widgets/step_one.dart';
import 'widgets/step_three.dart';
import 'widgets/step_two.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OnboardingViewModel>(
      create: (BuildContext context) =>
          OnboardingViewModel(context.read<AppStore>()),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (_, OnboardingViewModel vm, _) {
        return PopScope(
          // System back steps backward through onboarding.
          canPop: vm.currentStep == 0,
          onPopInvokedWithResult: (bool didPop, _) {
            if (!didPop) {
              vm.prevStep();
            }
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: vm.currentStep > 0
                ? AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      onPressed: vm.prevStep,
                    ),
                  )
                : null,
            body: PageView(
              controller: vm.pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const <Widget>[
                StepOne(),
                StepTwo(),
                StepThree(),
                StepNotifications(),
              ],
            ),
          ),
        );
      },
    );
  }
}
