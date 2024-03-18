import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/src/configurations/secret_config.dart';
import 'package:flutter_screen_lock/src/configurations/secrets_config.dart';

class SecretsWithShakingAnimation extends StatefulWidget {
  const SecretsWithShakingAnimation({
    super.key,
    required this.config,
    required this.length,
    required this.input,
    required this.verifyStream,
    required this.secretsBottom,
  });

  final SecretsConfig config;
  final int length;
  final ValueListenable<String> input;
  final Stream<bool> verifyStream;
  final Widget? secretsBottom;

  @override
  State<SecretsWithShakingAnimation> createState() => _SecretsWithShakingAnimationState();
}

class _SecretsWithShakingAnimationState extends State<SecretsWithShakingAnimation>
    with SingleTickerProviderStateMixin {
  late Animation<Offset> _animation;
  late AnimationController _animationController;
  late StreamSubscription<bool> _verifySubscription;

  @override
  void initState() {
    super.initState();

    _verifySubscription = widget.verifyStream.listen((valid) {
      if (!valid) {
        // shake animation when invalid
        _animationController.forward();
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );

    _animation = _animationController
        .drive(CurveTween(curve: Curves.elasticIn))
        .drive(Tween<Offset>(begin: Offset.zero, end: const Offset(0.05, 0)))
      ..addListener(() => setState(() {}))
      ..addStatusListener(
        (status) {
          if (status == AnimationStatus.completed) {
            _animationController.reverse();
          }
        },
      );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _verifySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Secrets(
        input: widget.input,
        length: widget.length,
        config: widget.config,
        secretsBottom: widget.secretsBottom,
      ),
    );
  }
}

class Secrets extends StatefulWidget {
  const Secrets({
    super.key,
    SecretsConfig? config,
    required this.input,
    required this.length,
    required this.secretsBottom,
  }) : config = config ?? const SecretsConfig();

  final SecretsConfig config;
  final ValueListenable<String> input;
  final int length;
  final Widget? secretsBottom;

  @override
  State<Secrets> createState() => _SecretsState();
}

class _SecretsState extends State<Secrets> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.input,
      builder: (context, value, child) => Padding(
        padding: widget.config.padding,
        child: Column(
          children: [
            Wrap(
              spacing: widget.config.spacing,
              children: List.generate(
                widget.length,
                (index) {
                  if (value.isEmpty) {
                    return Secret(
                      config: widget.config.secretConfig,
                      enabled: false,
                    );
                  }

                  return Secret(
                    config: widget.config.secretConfig,
                    enabled: index < value.length,
                  );
                },
                growable: false,
              ),
            ),
            if (widget.secretsBottom != null) widget.secretsBottom,
          ],
          mainAxisSize: MainAxisSize.min,
        ),
      ),
    );
  }
}

class Secret extends StatelessWidget {
  const Secret({
    super.key,
    SecretConfig? config,
    this.enabled = false,
  }) : config = config ?? const SecretConfig();

  final SecretConfig config;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (config.builder != null) {
      return config.builder!(
        context,
        config,
        enabled,
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled ? config.enabledColor : config.disabledColor,
        border: Border.all(
          width: config.borderSize,
          color: config.borderColor,
        ),
      ),
      width: config.size,
      height: config.size,
    );
  }
}
