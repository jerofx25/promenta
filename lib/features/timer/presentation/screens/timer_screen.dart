import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:IAEntrenar/utils/theme.dart';
import 'package:segment_display/segment_display.dart';

enum TimerMode { intervals, countUp, countDown, stopwatch, clock }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  TimerMode _mode = TimerMode.stopwatch;
  bool _isRunning = false;
  Timer? _timer;

  // Stopwatch
  int _stopwatchMs = 0;

  // CountUp / CountDown
  int _targetSeconds = 600; // 10 mins
  int _currentSeconds = 0;

  // Intervals
  int _workSeconds = 20;
  int _restSeconds = 10;
  int _rounds = 8;
  int _currentRound = 1;
  bool _isWork = true;
  int _intervalSeconds = 20;

  @override
  void initState() {
    super.initState();
    // Forzar orientación horizontal
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    // Ocultar barra de estado para inmersión total
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Si el modo inicial es reloj, iniciar el timer
    if (_mode == TimerMode.clock) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Restaurar orientación vertical
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Restaurar UI del sistema
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning && _mode != TimerMode.clock) return;

    setState(() {
      _isRunning = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        if (_mode == TimerMode.stopwatch) {
          _stopwatchMs += 10;
        } else if (_mode == TimerMode.countUp) {
          if (_stopwatchMs % 1000 == 0) {
            _currentSeconds++;
            if (_currentSeconds >= _targetSeconds) {
              _stopTimer();
              _playSound();
            }
          }
          _stopwatchMs += 10;
        } else if (_mode == TimerMode.countDown) {
          if (_stopwatchMs % 1000 == 0) {
            if (_currentSeconds > 0) {
              _currentSeconds--;
            } else {
              _stopTimer();
              _playSound();
            }
          }
          _stopwatchMs += 10;
        } else if (_mode == TimerMode.intervals) {
          if (_stopwatchMs % 1000 == 0) {
            if (_intervalSeconds > 0) {
              _intervalSeconds--;
            } else {
              if (_isWork) {
                _isWork = false;
                _intervalSeconds = _restSeconds;
                _playSound();
              } else {
                if (_currentRound < _rounds) {
                  _currentRound++;
                  _isWork = true;
                  _intervalSeconds = _workSeconds;
                  _playSound();
                } else {
                  _stopTimer();
                  _playSound();
                }
              }
            }
          }
          _stopwatchMs += 10;
        } else if (_mode == TimerMode.clock) {
          // El reloj se actualiza solo
        }
      });
    });
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
      _stopwatchMs = 0;
      if (_mode == TimerMode.countUp) {
        _currentSeconds = 0;
      } else if (_mode == TimerMode.countDown) {
        _currentSeconds = _targetSeconds;
      } else if (_mode == TimerMode.intervals) {
        _currentRound = 1;
        _isWork = true;
        _intervalSeconds = _workSeconds;
      }
    });
  }

  void _playSound() {
    // Aquí iría el sonido (beep). Por ahora solo mostramos un snackbar visual si no estamos en inmersivo.
  }

  void _togglePlayPause() {
    if (_mode == TimerMode.clock) return;
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  void _changeMode(TimerMode newMode) {
    _stopTimer();
    setState(() {
      _mode = newMode;
      _resetTimer();
      if (_mode == TimerMode.clock) {
        _startTimer();
      }
    });
    Navigator.pop(context);
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildSettingsMenu(),
    );
  }

  void _showConfigurationDialog() {
    int tempWork = _workSeconds;
    int tempRest = _restSeconds;
    int tempRounds = _rounds;
    int tempTarget = _targetSeconds;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111111),
              title: Text(
                _mode == TimerMode.intervals ? 'Configurar Intervalos' : 'Configurar Tiempo',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_mode == TimerMode.intervals) ...[
                      _buildNumberPicker('Trabajo (seg)', tempWork, (v) => setDialogState(() => tempWork = v), step: 5),
                      _buildNumberPicker('Descanso (seg)', tempRest, (v) => setDialogState(() => tempRest = v), step: 5),
                      _buildNumberPicker('Rondas', tempRounds, (v) => setDialogState(() => tempRounds = v), step: 1),
                    ] else if (_mode == TimerMode.countUp || _mode == TimerMode.countDown) ...[
                      _buildNumberPicker('Tiempo (seg)', tempTarget, (v) => setDialogState(() => tempTarget = v), step: 10),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_mode == TimerMode.intervals) {
                        _workSeconds = tempWork;
                        _restSeconds = tempRest;
                        _rounds = tempRounds;
                      } else {
                        _targetSeconds = tempTarget;
                      }
                      _resetTimer();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar', style: TextStyle(color: AppTheme.exerciseRingColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNumberPicker(String label, int value, ValueChanged<int> onChanged, {int step = 1, int min = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
                onPressed: () => onChanged(value - step >= min ? value - step : min),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$value',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white54),
                onPressed: () => onChanged(value + step),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem('H1', 'Intervalos', 'Intervalos de trabajo/descanso', TimerMode.intervals),
              const Divider(color: Colors.white24),
              _buildMenuItem('UP', 'Cuenta ascendente', '00:00 a 99:59', TimerMode.countUp),
              const Divider(color: Colors.white24),
              _buildMenuItem('dn', 'Cuenta atrás', '99:59 a 00:00', TimerMode.countDown),
              const Divider(color: Colors.white24),
              _buildMenuItem('cr', 'Cronómetro', 'Cuenta ascendente con milisegundos', TimerMode.stopwatch),
              const Divider(color: Colors.white24),
              _buildMenuItem('cL', 'Reloj', 'Hora actual', TimerMode.clock),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String prefix, String title, String subtitle, TimerMode mode) {
    final isSelected = _mode == mode;
    return ListTile(
      leading: SizedBox(
        width: 40,
        child: Text(
          prefix,
          style: GoogleFonts.vt323(
            fontSize: 28,
            color: AppTheme.standRingColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 14),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.exerciseRingColor) : null,
      onTap: () => _changeMode(mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _togglePlayPause,
        onDoubleTap: _resetTimer,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              children: [
                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botón atrás e Indicadores de modo
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        _buildModeIndicator('rd', _mode == TimerMode.intervals, AppTheme.standRingColor),
                        const SizedBox(width: 12),
                        _buildModeIndicator('H1', _mode == TimerMode.intervals, Colors.redAccent),
                        const SizedBox(width: 12),
                        _buildModeIndicator('UP', _mode == TimerMode.countUp, Colors.redAccent),
                        const SizedBox(width: 12),
                        _buildModeIndicator('dn', _mode == TimerMode.countDown, Colors.redAccent),
                        const SizedBox(width: 12),
                        _buildModeIndicator('cr', _mode == TimerMode.stopwatch, Colors.redAccent),
                      ],
                    ),
                    // Botón de menú y configuración
                    Row(
                      children: [
                        if (_mode == TimerMode.intervals || _mode == TimerMode.countUp || _mode == TimerMode.countDown)
                          IconButton(
                            icon: const Icon(Icons.settings_suggest, color: Colors.white, size: 32),
                            onPressed: _showConfigurationDialog,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        if (_mode == TimerMode.intervals || _mode == TimerMode.countUp || _mode == TimerMode.countDown)
                          const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white, size: 32),
                          onPressed: _showSettings,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Main Display
                FittedBox(
                  fit: BoxFit.contain,
                  child: _buildMainDisplay(),
                ),
                
                const Spacer(),
                
                // Bottom Bar (Logo)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    
                    if (_mode != TimerMode.clock)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(_isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill),
                            color: Colors.white,
                            iconSize: 48,
                            onPressed: _togglePlayPause,
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.stop_circle),
                            color: Colors.white,
                            iconSize: 48,
                            onPressed: () {
                              _stopTimer();
                              _resetTimer();
                            },
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            color: Colors.white,
                            iconSize: 40,
                            onPressed: _resetTimer,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeIndicator(String text, bool isActive, Color activeColor) {
    return Text(
      text,
      style: GoogleFonts.vt323(
        fontSize: 28,
        color: isActive ? activeColor : Colors.white.withOpacity(0.1),
        shadows: isActive ? [Shadow(color: activeColor, blurRadius: 10)] : null,
      ),
    );
  }

  Widget _buildMainDisplay() {
    switch (_mode) {
      case TimerMode.stopwatch:
        int mins = (_stopwatchMs / 60000).floor();
        int secs = (_stopwatchMs / 1000).floor() % 60;
        int ms = (_stopwatchMs % 1000) ~/ 10;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentDisplay(mins.toString().padLeft(2, '0'), const Color(0xFF0B6FFF), 2),
            const SizedBox(width: 16),
            _buildSegmentDisplay('${secs.toString().padLeft(2, '0')}:${ms.toString().padLeft(2, '0')}', const Color(0xFFFF1E12), 5),
          ],
        );
      case TimerMode.countUp:
      case TimerMode.countDown:
        int mins = (_currentSeconds / 60).floor();
        int secs = _currentSeconds % 60;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentDisplay(mins.toString().padLeft(2, '0'), const Color(0xFF0B6FFF), 2),
            const SizedBox(width: 16),
            _buildSegmentDisplay(secs.toString().padLeft(2, '0'), const Color(0xFFFF1E12), 2),
          ],
        );
      case TimerMode.intervals:
        int mins = (_intervalSeconds / 60).floor();
        int secs = _intervalSeconds % 60;
        final color = _isWork ? const Color(0xFFFF1E12) : const Color(0xFF0B6FFF);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentDisplay(_currentRound.toString().padLeft(2, '0'), const Color(0xFF0B6FFF), 2),
            const SizedBox(width: 16),
            _buildSegmentDisplay('${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}', color, 5),
          ],
        );
      case TimerMode.clock:
        final now = DateTime.now();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentDisplay(now.hour.toString().padLeft(2, '0'), const Color(0xFF0B6FFF), 2),
            const SizedBox(width: 16),
            _buildSegmentDisplay('${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}', const Color(0xFFFF1E12), 5),
          ],
        );
    }
  }

  Widget _buildSegmentDisplay(String value, Color color, int charCount) {
    return SevenSegmentDisplay(
      value: value,
      size: 14.0, // Tamaño base para hacer los números grandes
      characterCount: charCount,
      backgroundColor: Colors.transparent,
      segmentStyle: HexSegmentStyle(
        enabledColor: color,
        disabledColor: const Color(0xFF101010),
      ),
    );
  }
}
