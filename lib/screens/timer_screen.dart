import 'dart:async';
import 'package:flutter/material.dart';

enum TimerMode { stopwatch, countdown, interval }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  TimerMode _currentMode = TimerMode.stopwatch;

  // Stopwatch variables
  bool _isRunning = false;
  int _elapsedMilliseconds = 0;
  Timer? _timer;

  // Countdown variables
  int _countdownTime = 60; // Seconds
  int _remainingTime = 60;
  final TextEditingController _countdownMinutesController =
      TextEditingController(text: '1');
  final TextEditingController _countdownSecondsController =
      TextEditingController(text: '0');

  // Interval variables
  int _workTime = 30; // Seconds
  int _restTime = 10; // Seconds
  int _intervals = 5;
  int _currentInterval = 0;
  bool _isWorkPeriod = true;
  final TextEditingController _workTimeController = TextEditingController(text: '30');
  final TextEditingController _restTimeController = TextEditingController(text: '10');
  final TextEditingController _intervalsController = TextEditingController(text: '5');

  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Timer variables
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _countdownMinutesController.dispose();
    _countdownSecondsController.dispose();
    _workTimeController.dispose();
    _restTimeController.dispose();
    _intervalsController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    // Different timer behavior based on mode
    switch (_currentMode) {
      case TimerMode.stopwatch:
        _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
          setState(() {
            _elapsedMilliseconds += 10;
          });
        });
        break;

      case TimerMode.countdown:
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_remainingTime > 0) {
              _remainingTime--;
            } else {
              _stopTimer();
              _playSound();
            }
          });
        });
        break;

      case TimerMode.interval:
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_isWorkPeriod) {
              if (_remainingTime > 0) {
                _remainingTime--;
              } else {
                // Switch to rest period
                _isWorkPeriod = false;
                _remainingTime = _restTime;
                _playSound();
              }
            } else {
              if (_remainingTime > 0) {
                _remainingTime--;
              } else {
                _currentInterval++;

                if (_currentInterval >= _intervals) {
                  // Finished all intervals
                  _stopTimer();
                  _playSound();
                  return;
                }

                // Switch back to work period
                _isWorkPeriod = true;
                _remainingTime = _workTime;
                _playSound();
              }
            }
          });
        });
        break;
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      switch (_currentMode) {
        case TimerMode.stopwatch:
          _elapsedMilliseconds = 0;
          break;
        case TimerMode.countdown:
          _remainingTime = _countdownTime;
          break;
        case TimerMode.interval:
          _remainingTime = _workTime;
          _currentInterval = 0;
          _isWorkPeriod = true;
          break;
      }
    });
  }

  void _updateCountdownTime() {
    final minutes = int.tryParse(_countdownMinutesController.text) ?? 0;
    final seconds = int.tryParse(_countdownSecondsController.text) ?? 0;
    setState(() {
      _countdownTime = (minutes * 60) + seconds;
      _remainingTime = _countdownTime;
    });
  }

  void _updateIntervalSettings() {
    final workTime = int.tryParse(_workTimeController.text) ?? 30;
    final restTime = int.tryParse(_restTimeController.text) ?? 10;
    final intervals = int.tryParse(_intervalsController.text) ?? 5;

    setState(() {
      _workTime = workTime;
      _restTime = restTime;
      _intervals = intervals;
      _remainingTime = _workTime;
      _currentInterval = 0;
      _isWorkPeriod = true;
    });
  }

  void _playSound() {
    // Sound would be played here if using audio plugin
    // For now, we'll just display a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_currentMode == TimerMode.countdown
            ? 'Tiempo completado!'
            : _isWorkPeriod
                ? 'Comenzar trabajo!'
                : 'Comenzar descanso!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatTime(int milliseconds) {
    int hundreds = (milliseconds / 10).floor() % 100;
    int seconds = (milliseconds / 1000).floor() % 60;
    int minutes = (milliseconds / 60000).floor() % 60;
    int hours = (milliseconds / 3600000).floor();

    String hoursStr = hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : '';
    String minutesStr = '${minutes.toString().padLeft(2, '0')}:';
    String secondsStr = seconds.toString().padLeft(2, '0');
    String hundredsStr = hundreds.toString().padLeft(2, '0');

    return _currentMode == TimerMode.stopwatch
        ? '$hoursStr$minutesStr$secondsStr.$hundredsStr'
        : '$hoursStr$minutesStr$secondsStr';
  }

  String _formatCountdownTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildStopwatchMode() {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 40),
        // Display
        Container(
          height: 240,
          width: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withOpacity(0.1),
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 4,
            ),
          ),
          child: Center(
            child: AnimatedSlide(
              offset: Offset(0, _isRunning ? 0.0 : 0.05),
              duration: const Duration(milliseconds: 200),
              child: Text(
                _formatTime(_elapsedMilliseconds),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 50),
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
              onPressed: _resetTimer,
              icon: Icons.refresh,
              label: 'Reiniciar',
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 32),
            _buildControlButton(
              onPressed: _isRunning ? _stopTimer : _startTimer,
              icon: _isRunning ? Icons.pause : Icons.play_arrow,
              label: _isRunning ? 'Pausar' : 'Iniciar',
              color: _isRunning
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.primary,
              large: true,
            ),
            const SizedBox(width: 32),
            _buildControlButton(
              onPressed: () {
                // Functionality to record lap time would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Marca: ${_formatTime(_elapsedMilliseconds)}')),
                );
              },
              icon: Icons.flag,
              label: 'Marca',
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountdownMode() {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 40),
        // Display
        Container(
          height: 240,
          width: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.secondary.withOpacity(0.1),
            border: Border.all(
              color: theme.colorScheme.secondary,
              width: 4,
            ),
          ),
          child: Center(
            child: AnimatedSlide(
              offset: Offset(0, _isRunning ? 0.0 : 0.05),
              duration: const Duration(milliseconds: 200),
              child: Text(
                _formatCountdownTime(_remainingTime),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        // Settings (only visible when timer is not running)
        if (!_isRunning) ...[
          // Fixed bracket syntax here
          Text(
            'Ajustar tiempo',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _countdownMinutesController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Min',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                ':',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _countdownSecondsController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Seg',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _updateCountdownTime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Aplicar'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
              onPressed: _resetTimer,
              icon: Icons.refresh,
              label: 'Reiniciar',
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 32),
            _buildControlButton(
              onPressed: _isRunning ? _stopTimer : _startTimer,
              icon: _isRunning ? Icons.pause : Icons.play_arrow,
              label: _isRunning ? 'Pausar' : 'Iniciar',
              color: _isRunning
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
              large: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIntervalMode() {
    final theme = Theme.of(context);
    final color =
        _isWorkPeriod ? theme.colorScheme.primary : theme.colorScheme.tertiary;

    return Column(
      children: [
        const SizedBox(height: 20),
        // Interval status
        if (_isRunning || _currentInterval > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isWorkPeriod ? Icons.fitness_center : Icons.nightlight_round,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  _isWorkPeriod ? 'Trabajo' : 'Descanso',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intervalo ${_currentInterval + 1} de $_intervals',
            style: theme.textTheme.titleSmall,
          ),
        ],
        const SizedBox(height: 20),
        // Display
        Container(
          height: 240,
          width: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color,
              width: 4,
            ),
          ),
          child: Center(
            child: AnimatedSlide(
              offset: Offset(0, _isRunning ? 0.0 : 0.05),
              duration: const Duration(milliseconds: 200),
              child: Text(
                _formatCountdownTime(_remainingTime),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        // Settings (only visible when timer is not running)
        if (!_isRunning && _currentInterval == 0) ...[
          Text(
            'Ajustar intervalos',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _workTimeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Trabajo',
                        suffixText: 's',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trabajo',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _restTimeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Descanso',
                        suffixText: 's',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Descanso',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _intervalsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Ciclos',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Repeticiones',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _updateIntervalSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Aplicar Configuración'),
          ),
          const SizedBox(height: 20),
        ],
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
              onPressed: _resetTimer,
              icon: Icons.refresh,
              label: 'Reiniciar',
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 32),
            _buildControlButton(
              onPressed: _isRunning ? _stopTimer : _startTimer,
              icon: _isRunning ? Icons.pause : Icons.play_arrow,
              label: _isRunning ? 'Pausar' : 'Iniciar',
              color: _isRunning
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.primary,
              large: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool large = false,
  }) {
    return Column(
      children: [
        SizedBox(
          height: large ? 80 : 60,
          width: large ? 80 : 60,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: Icon(
              icon,
              size: large ? 36 : 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Timer',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background image
          Opacity(
            opacity: 0.07,
            child: Image.network(
              "https://pixabay.com/get/g6b756a33a6bfcadafa5413f691564040f3b906616d16792393e6a09db7ce2d605641e0ed0284b1cee19c142d9cdf88bdb67de70b9998d3c8579372d5e7fbd281_1280.jpg",
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Mode selector
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildModeTab(
                            icon: Icons.timer,
                            label: 'Cronómetro',
                            isSelected: _currentMode == TimerMode.stopwatch,
                            onTap: () => setState(() {
                              _currentMode = TimerMode.stopwatch;
                              _resetTimer();
                            }),
                          ),
                        ),
                        Expanded(
                          child: _buildModeTab(
                            icon: Icons.hourglass_empty,
                            label: 'Temporizador',
                            isSelected: _currentMode == TimerMode.countdown,
                            onTap: () => setState(() {
                              _currentMode = TimerMode.countdown;
                              _resetTimer();
                            }),
                          ),
                        ),
                        Expanded(
                          child: _buildModeTab(
                            icon: Icons.repeat,
                            label: 'Intervalos',
                            isSelected: _currentMode == TimerMode.interval,
                            onTap: () => setState(() {
                              _currentMode = TimerMode.interval;
                              _resetTimer();
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Selected mode content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _currentMode == TimerMode.stopwatch
                        ? _buildStopwatchMode()
                        : _currentMode == TimerMode.countdown
                            ? _buildCountdownMode()
                            : _buildIntervalMode(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
