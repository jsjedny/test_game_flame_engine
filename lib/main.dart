// import 'dart:async';
// import 'package:flame/components.dart';
// import 'package:flame/events.dart';
// import 'package:flame/game.dart';
// import 'package:flutter/material.dart';

// void main() {
//   runApp(GameWidget(game: FlameGame(world: MyWorld())));
// }

// class MyWorld extends World {
//   @override
//   Future<void> onLoad() async {
//     add(Player(position: Vector2(0, 0)));
//     return super.onLoad();
//   }
// }

// class Player extends SpriteComponent with TapCallbacks {
//   Player({super.position})
//     : super(size: Vector2.all(200), anchor: Anchor.center);

//   @override
//   Future<void> onLoad() async {
//     sprite = await Sprite.load('player.png');
//     return super.onLoad();
//   }

//   @override
//   void onTapUp(TapUpEvent event) {
//     size += Vector2.all(20);
//     super.onTapUp(event);
//   }

//   @override
//   void onTapDown(TapDownEvent event) {
//     size -= Vector2.all(20);
//     super.onTapDown(event);
//   }
// }

// ============================================================================
// CAR DODGE - a single-file Flutter + Flame racing game.
//
// No image assets are used at all — every car, the road, the grass and the
// scenery are drawn live with Canvas/Paint inside each component's render()
// method (gradients, shadows, rounded shapes). This keeps the whole game to
// one file and looks crisp on any screen size / pixel density.
//
// SETUP:
//   1) Create a new Flutter project:  flutter create car_dodge
//   2) Replace lib/main.dart with this file.
//   3) In pubspec.yaml, under dependencies, add:
//        flame: ^1.18.0
//   4) flutter pub get
//   5) flutter run
//
// HOW TO PLAY:
//   Drag left / right anywhere on screen to steer your car and dodge the
//   oncoming traffic. The longer you survive, the faster and busier the
//   road gets. Tap "PLAY" / "RETRY" on the overlay screens to (re)start.
// ============================================================================

import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CarDodgeApp());
}

class CarDodgeApp extends StatelessWidget {
  const CarDodgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Car Dodge',
      home: Scaffold(
        body: GameWidget<CarGame>.controlled(
          gameFactory: CarGame.new,
          overlayBuilderMap: {
            'Start': (context, game) => StartOverlay(game: game),
            'GameOver': (context, game) => GameOverOverlay(game: game),
          },
          initialActiveOverlays: const ['Start'],
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN GAME
// ============================================================================

class CarGame extends FlameGame with HasCollisionDetection, DragCallbacks {
  late RoadComponent road;
  late PlayerCar player;
  late TextComponent scoreText;

  double score = 0;
  double gameSpeed = 320;
  double _spawnTimer = 0;
  double _spawnInterval = 1.3;
  bool isGameOver = false;
  bool isRunning = false;

  final Random rng = Random();

  static const _enemyColors = [
    Color(0xFFE53935), // red
    Color(0xFF3949AB), // indigo
    Color(0xFFFDD835), // yellow
    Color(0xFF43A047), // green
    Color(0xFF8E24AA), // purple
    Color(0xFFFB8C00), // orange
  ];

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    road = RoadComponent();
    await add(road);

    scoreText = TextComponent(
      text: 'SCORE 0',
      position: Vector2(20, 40),
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(1, 2)),
          ],
        ),
      ),
    );
    await add(scoreText);
  }

  void startGame() {
    isGameOver = false;
    score = 0;
    gameSpeed = 320;
    _spawnInterval = 1.3;
    _spawnTimer = 0;
    scoreText.text = 'SCORE 0';

    for (final e in children.whereType<EnemyCar>().toList()) {
      e.removeFromParent();
    }

    if (children.whereType<PlayerCar>().isEmpty) {
      player = PlayerCar()..position = Vector2(size.x / 2, size.y - 160);
      add(player);
    } else {
      player.position = Vector2(size.x / 2, size.y - 160);
    }

    overlays.remove('Start');
    overlays.remove('GameOver');
    isRunning = true;
  }

  void triggerGameOver() {
    if (isGameOver) return;
    isGameOver = true;
    isRunning = false;
    overlays.add('GameOver');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isRunning) return;

    score += dt * 12;
    scoreText.text = 'SCORE ${score.toInt()}';

    gameSpeed += dt * 5; // gradual ramp-up
    _spawnInterval = max(0.45, 1.3 - score / 700);

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnEnemy();
    }
  }

  void _spawnEnemy() {
    final lanes = road.laneCenters;
    if (lanes.isEmpty) return;
    final x = lanes[rng.nextInt(lanes.length)];
    final color = _enemyColors[rng.nextInt(_enemyColors.length)];
    add(EnemyCar(color: color)..position = Vector2(x, -160));
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!isRunning) return;
    player.moveBy(event.localDelta.x);
  }
}

// ============================================================================
// ROAD / SCENERY  (procedurally drawn — no images)
// ============================================================================

class RoadComponent extends PositionComponent with HasGameReference<CarGame> {
  double _dashScroll = 0;
  double _treeScroll = 0;

  double roadLeft = 0;
  double roadRight = 0;
  List<double> laneCenters = [];
  static const int laneCount = 3;

  RoadComponent() : super(priority: -1);

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
    final roadWidth = gameSize.x * 0.78;
    roadLeft = (gameSize.x - roadWidth) / 2;
    roadRight = roadLeft + roadWidth;
    laneCenters = List.generate(
      laneCount,
      (i) => roadLeft + roadWidth * (i + 0.5) / laneCount,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isRunning) {
      _dashScroll = (_dashScroll + game.gameSpeed * dt) % 80;
      _treeScroll = (_treeScroll + game.gameSpeed * 0.6 * dt) % 160;
    }
  }

  @override
  void render(Canvas canvas) {
    final s = game.size;

    // --- Sky/grass background -------------------------------------------
    final grassPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, s.x, s.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, s.x, s.y), grassPaint);

    // --- Roadside trees (parallax) ----------------------------------------
    _drawTreeColumn(canvas, roadLeft - 40, s.y);
    _drawTreeColumn(canvas, roadRight + 40, s.y);

    // --- Road surface -------------------------------------------------------
    final roadRect = Rect.fromLTWH(roadLeft, 0, roadRight - roadLeft, s.y);
    final roadPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3A3A3A), Color(0xFF1C1C1C), Color(0xFF3A3A3A)],
        stops: [0, 0.5, 1],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(roadRect);
    canvas.drawRect(roadRect, roadPaint);

    // Road shoulders (rumble strips)
    final shoulderPaint = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawRect(Rect.fromLTWH(roadLeft - 6, 0, 6, s.y), shoulderPaint);
    canvas.drawRect(Rect.fromLTWH(roadRight, 0, 6, s.y), shoulderPaint);

    // Lane dashes
    final dashPaint = Paint()..color = Colors.white.withOpacity(0.85);
    final laneWidth = (roadRight - roadLeft) / laneCount;
    for (int i = 1; i < laneCount; i++) {
      final x = roadLeft + laneWidth * i;
      double y = -80 + _dashScroll;
      while (y < s.y) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 4, y, 8, 42),
            const Radius.circular(4),
          ),
          dashPaint,
        );
        y += 80;
      }
    }
  }

  void _drawTreeColumn(Canvas canvas, double x, double screenH) {
    final trunkPaint = Paint()..color = const Color(0xFF6D4C41);
    final leafPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
      ).createShader(Rect.fromCircle(center: Offset(x, 0), radius: 26));

    double y = -160 + _treeScroll;
    int i = 0;
    while (y < screenH + 40) {
      final wobble = (i.isEven ? -8.0 : 8.0);
      canvas.drawRect(Rect.fromLTWH(x + wobble - 4, y + 26, 8, 26), trunkPaint);
      canvas.drawCircle(Offset(x + wobble, y + 14), 26, leafPaint);
      y += 160;
      i++;
    }
  }
}

// ============================================================================
// CARS — shared drawing routine + player/enemy components
// ============================================================================

void _drawCarBody(
  Canvas canvas,
  Vector2 size,
  Color color, {
  required bool facingUp,
}) {
  final w = size.x;
  final h = size.y;

  // Soft ground shadow
  final shadowPaint = Paint()
    ..color = Colors.black.withOpacity(0.28)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  canvas.drawOval(
    Rect.fromLTWH(w * 0.06, h * 0.88, w * 0.88, h * 0.16),
    shadowPaint,
  );

  // Body
  final bodyRect = Rect.fromLTWH(0, h * 0.04, w, h * 0.86);
  final bodyRRect = RRect.fromRectAndRadius(
    bodyRect,
    const Radius.circular(20),
  );
  final bodyPaint = Paint()
    ..shader = LinearGradient(
      colors: [_lighten(color, 0.18), color, _darken(color, 0.28)],
      stops: const [0, 0.5, 1],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(bodyRect);
  canvas.drawRRect(bodyRRect, bodyPaint);

  // Body outline
  canvas.drawRRect(
    bodyRRect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _darken(color, 0.45),
  );

  // Glossy highlight stripe
  final glossPaint = Paint()..color = Colors.white.withOpacity(0.18);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.08, w * 0.18, h * 0.7),
      const Radius.circular(10),
    ),
    glossPaint,
  );

  // Windshield / rear window + roof
  final windowPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFFB3E5FC), Color(0xFF4FC3F7)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(w * 0.16, h * 0.30, w * 0.68, h * 0.30));
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.30, w * 0.68, h * 0.30),
      const Radius.circular(8),
    ),
    windowPaint,
  );
  // window divider
  canvas.drawLine(
    Offset(w * 0.5, h * 0.30),
    Offset(w * 0.5, h * 0.60),
    Paint()
      ..color = _darken(color, 0.4)
      ..strokeWidth = 2,
  );

  // Wheels
  final wheelPaint = Paint()..color = const Color(0xFF111111);
  final rimPaint = Paint()..color = const Color(0xFFBDBDBD);
  final wheelPositions = [
    Offset(w * -0.02, h * 0.22),
    Offset(w * 1.02, h * 0.22),
    Offset(w * -0.02, h * 0.78),
    Offset(w * 1.02, h * 0.78),
  ];
  for (final p in wheelPositions) {
    final wheelRect = Rect.fromCenter(
      center: p,
      width: w * 0.16,
      height: h * 0.16,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(wheelRect, const Radius.circular(4)),
      wheelPaint,
    );
    canvas.drawCircle(p, w * 0.045, rimPaint);
  }

  // Headlights / taillights — position depends on facing direction
  final frontY = facingUp ? h * 0.06 : h * 0.86;
  final backY = facingUp ? h * 0.86 : h * 0.06;

  final headlightPaint = Paint()..color = const Color(0xFFFFF59D);
  final taillightPaint = Paint()..color = const Color(0xFFE53935);

  canvas.drawCircle(Offset(w * 0.22, frontY), w * 0.06, headlightPaint);
  canvas.drawCircle(Offset(w * 0.78, frontY), w * 0.06, headlightPaint);
  canvas.drawRect(
    Rect.fromCenter(
      center: Offset(w * 0.22, backY),
      width: w * 0.14,
      height: h * 0.03,
    ),
    taillightPaint,
  );
  canvas.drawRect(
    Rect.fromCenter(
      center: Offset(w * 0.78, backY),
      width: w * 0.14,
      height: h * 0.03,
    ),
    taillightPaint,
  );
}

Color _darken(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

Color _lighten(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

class PlayerCar extends PositionComponent
    with CollisionCallbacks, HasGameReference<CarGame> {
  PlayerCar() : super(size: Vector2(70, 118), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await add(
      RectangleHitbox(
        size: Vector2(size.x * 0.8, size.y * 0.85),
        position: Vector2(size.x * 0.1, size.y * 0.08),
      ),
    );
  }

  void moveBy(double dx) {
    final road = game.road;
    position.x = (position.x + dx).clamp(
      road.roadLeft + size.x / 2 + 4,
      road.roadRight - size.x / 2 - 4,
    );
  }

  @override
  void render(Canvas canvas) {
    _drawCarBody(canvas, size, const Color(0xFF1E88E5), facingUp: true);
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    if (other is EnemyCar) {
      game.triggerGameOver();
    }
  }
}

class EnemyCar extends PositionComponent
    with CollisionCallbacks, HasGameReference<CarGame> {
  final Color color;
  EnemyCar({required this.color})
    : super(size: Vector2(70, 118), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await add(
      RectangleHitbox(
        size: Vector2(size.x * 0.8, size.y * 0.85),
        position: Vector2(size.x * 0.1, size.y * 0.08),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isRunning) return;
    position.y += game.gameSpeed * dt;
    if (position.y - size.y / 2 > game.size.y) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    _drawCarBody(canvas, size, color, facingUp: false);
  }
}

// ============================================================================
// UI OVERLAYS
// ============================================================================

class StartOverlay extends StatelessWidget {
  final CarGame game;
  const StartOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.55),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CAR DODGE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Drag left / right to steer.\nDodge the traffic and survive!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 32),
          _PlayButton(label: 'PLAY', onTap: game.startGame),
        ],
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  final CarGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.65),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'GAME OVER',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Score: ${game.score.toInt()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          _PlayButton(label: 'RETRY', onTap: game.startGame),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PlayButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        elevation: 6,
      ),
      child: Text(label),
    );
  }
}
