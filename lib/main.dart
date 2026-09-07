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

// import 'dart:async';
// import 'dart:math';
// import 'package:flame/collisions.dart';
// import 'package:flame/components.dart';
// import 'package:flame/events.dart';
// import 'package:flame/game.dart';
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const CarDodgeApp());
// }

// class CarDodgeApp extends StatelessWidget {
//   const CarDodgeApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Car Dodge',
//       home: Scaffold(
//         body: GameWidget<CarGame>.controlled(
//           gameFactory: CarGame.new,
//           overlayBuilderMap: {
//             'Start': (context, game) => StartOverlay(game: game),
//             'GameOver': (context, game) => GameOverOverlay(game: game),
//           },
//           initialActiveOverlays: const ['Start'],
//         ),
//       ),
//     );
//   }
// }

// // ============================================================================
// // MAIN GAME
// // ============================================================================

// class CarGame extends FlameGame with HasCollisionDetection, DragCallbacks {
//   late RoadComponent road;
//   late PlayerCar player;
//   late TextComponent scoreText;

//   double score = 0;
//   double gameSpeed = 320;
//   double _spawnTimer = 0;
//   double _spawnInterval = 1.3;
//   bool isGameOver = false;
//   bool isRunning = false;

//   final Random rng = Random();

//   static const _enemyColors = [
//     Color(0xFFE53935), // red
//     Color(0xFF3949AB), // indigo
//     Color(0xFFFDD835), // yellow
//     Color(0xFF43A047), // green
//     Color(0xFF8E24AA), // purple
//     Color(0xFFFB8C00), // orange
//   ];

//   @override
//   Color backgroundColor() => const Color(0xFF87CEEB);

//   @override
//   Future<void> onLoad() async {
//     await super.onLoad();

//     road = RoadComponent();
//     await add(road);

//     scoreText = TextComponent(
//       text: 'SCORE 0',
//       position: Vector2(20, 40),
//       priority: 10,
//       textRenderer: TextPaint(
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 26,
//           fontWeight: FontWeight.w900,
//           letterSpacing: 1,
//           shadows: [
//             Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(1, 2)),
//           ],
//         ),
//       ),
//     );
//     await add(scoreText);
//   }

//   void startGame() {
//     isGameOver = false;
//     score = 0;
//     gameSpeed = 320;
//     _spawnInterval = 1.3;
//     _spawnTimer = 0;
//     scoreText.text = 'SCORE 0';

//     for (final e in children.whereType<EnemyCar>().toList()) {
//       e.removeFromParent();
//     }

//     if (children.whereType<PlayerCar>().isEmpty) {
//       player = PlayerCar()..position = Vector2(size.x / 2, size.y - 160);
//       add(player);
//     } else {
//       player.position = Vector2(size.x / 2, size.y - 160);
//     }

//     overlays.remove('Start');
//     overlays.remove('GameOver');
//     isRunning = true;
//   }

//   void triggerGameOver() {
//     if (isGameOver) return;
//     isGameOver = true;
//     isRunning = false;
//     overlays.add('GameOver');
//   }

//   @override
//   void update(double dt) {
//     super.update(dt);
//     if (!isRunning) return;

//     score += dt * 12;
//     scoreText.text = 'SCORE ${score.toInt()}';

//     gameSpeed += dt * 5; // gradual ramp-up
//     _spawnInterval = max(0.45, 1.3 - score / 700);

//     _spawnTimer += dt;
//     if (_spawnTimer >= _spawnInterval) {
//       _spawnTimer = 0;
//       _spawnEnemy();
//     }
//   }

//   void _spawnEnemy() {
//     final lanes = road.laneCenters;
//     if (lanes.isEmpty) return;
//     final x = lanes[rng.nextInt(lanes.length)];
//     final color = _enemyColors[rng.nextInt(_enemyColors.length)];
//     add(EnemyCar(color: color)..position = Vector2(x, -160));
//   }

//   @override
//   void onDragUpdate(DragUpdateEvent event) {
//     super.onDragUpdate(event);
//     if (!isRunning) return;
//     player.moveBy(event.localDelta.x);
//   }
// }

// // ============================================================================
// // ROAD / SCENERY  (procedurally drawn — no images)
// // ============================================================================

// class RoadComponent extends PositionComponent with HasGameReference<CarGame> {
//   double _dashScroll = 0;
//   double _treeScroll = 0;

//   double roadLeft = 0;
//   double roadRight = 0;
//   List<double> laneCenters = [];
//   static const int laneCount = 3;

//   RoadComponent() : super(priority: -1);

//   @override
//   void onGameResize(Vector2 gameSize) {
//     super.onGameResize(gameSize);
//     size = gameSize;
//     final roadWidth = gameSize.x * 0.78;
//     roadLeft = (gameSize.x - roadWidth) / 2;
//     roadRight = roadLeft + roadWidth;
//     laneCenters = List.generate(
//       laneCount,
//       (i) => roadLeft + roadWidth * (i + 0.5) / laneCount,
//     );
//   }

//   @override
//   void update(double dt) {
//     super.update(dt);
//     if (game.isRunning) {
//       _dashScroll = (_dashScroll + game.gameSpeed * dt) % 80;
//       _treeScroll = (_treeScroll + game.gameSpeed * 0.6 * dt) % 160;
//     }
//   }

//   @override
//   void render(Canvas canvas) {
//     final s = game.size;

//     // --- Sky/grass background -------------------------------------------
//     final grassPaint = Paint()
//       ..shader = const LinearGradient(
//         colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//       ).createShader(Rect.fromLTWH(0, 0, s.x, s.y));
//     canvas.drawRect(Rect.fromLTWH(0, 0, s.x, s.y), grassPaint);

//     // --- Roadside trees (parallax) ----------------------------------------
//     _drawTreeColumn(canvas, roadLeft - 40, s.y);
//     _drawTreeColumn(canvas, roadRight + 40, s.y);

//     // --- Road surface -------------------------------------------------------
//     final roadRect = Rect.fromLTWH(roadLeft, 0, roadRight - roadLeft, s.y);
//     final roadPaint = Paint()
//       ..shader = const LinearGradient(
//         colors: [Color(0xFF3A3A3A), Color(0xFF1C1C1C), Color(0xFF3A3A3A)],
//         stops: [0, 0.5, 1],
//         begin: Alignment.centerLeft,
//         end: Alignment.centerRight,
//       ).createShader(roadRect);
//     canvas.drawRect(roadRect, roadPaint);

//     // Road shoulders (rumble strips)
//     final shoulderPaint = Paint()..color = Colors.white.withOpacity(0.9);
//     canvas.drawRect(Rect.fromLTWH(roadLeft - 6, 0, 6, s.y), shoulderPaint);
//     canvas.drawRect(Rect.fromLTWH(roadRight, 0, 6, s.y), shoulderPaint);

//     // Lane dashes
//     final dashPaint = Paint()..color = Colors.white.withOpacity(0.85);
//     final laneWidth = (roadRight - roadLeft) / laneCount;
//     for (int i = 1; i < laneCount; i++) {
//       final x = roadLeft + laneWidth * i;
//       double y = -80 + _dashScroll;
//       while (y < s.y) {
//         canvas.drawRRect(
//           RRect.fromRectAndRadius(
//             Rect.fromLTWH(x - 4, y, 8, 42),
//             const Radius.circular(4),
//           ),
//           dashPaint,
//         );
//         y += 80;
//       }
//     }
//   }

//   void _drawTreeColumn(Canvas canvas, double x, double screenH) {
//     final trunkPaint = Paint()..color = const Color(0xFF6D4C41);
//     final leafPaint = Paint()
//       ..shader = const RadialGradient(
//         colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
//       ).createShader(Rect.fromCircle(center: Offset(x, 0), radius: 26));

//     double y = -160 + _treeScroll;
//     int i = 0;
//     while (y < screenH + 40) {
//       final wobble = (i.isEven ? -8.0 : 8.0);
//       canvas.drawRect(Rect.fromLTWH(x + wobble - 4, y + 26, 8, 26), trunkPaint);
//       canvas.drawCircle(Offset(x + wobble, y + 14), 26, leafPaint);
//       y += 160;
//       i++;
//     }
//   }
// }

// // ============================================================================
// // CARS — shared drawing routine + player/enemy components
// // ============================================================================

// void _drawCarBody(
//   Canvas canvas,
//   Vector2 size,
//   Color color, {
//   required bool facingUp,
// }) {
//   final w = size.x;
//   final h = size.y;

//   // Soft ground shadow
//   final shadowPaint = Paint()
//     ..color = Colors.black.withOpacity(0.28)
//     ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
//   canvas.drawOval(
//     Rect.fromLTWH(w * 0.06, h * 0.88, w * 0.88, h * 0.16),
//     shadowPaint,
//   );

//   // Body
//   final bodyRect = Rect.fromLTWH(0, h * 0.04, w, h * 0.86);
//   final bodyRRect = RRect.fromRectAndRadius(
//     bodyRect,
//     const Radius.circular(20),
//   );
//   final bodyPaint = Paint()
//     ..shader = LinearGradient(
//       colors: [_lighten(color, 0.18), color, _darken(color, 0.28)],
//       stops: const [0, 0.5, 1],
//       begin: Alignment.centerLeft,
//       end: Alignment.centerRight,
//     ).createShader(bodyRect);
//   canvas.drawRRect(bodyRRect, bodyPaint);

//   // Body outline
//   canvas.drawRRect(
//     bodyRRect,
//     Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2
//       ..color = _darken(color, 0.45),
//   );

//   // Glossy highlight stripe
//   final glossPaint = Paint()..color = Colors.white.withOpacity(0.18);
//   canvas.drawRRect(
//     RRect.fromRectAndRadius(
//       Rect.fromLTWH(w * 0.12, h * 0.08, w * 0.18, h * 0.7),
//       const Radius.circular(10),
//     ),
//     glossPaint,
//   );

//   // Windshield / rear window + roof
//   final windowPaint = Paint()
//     ..shader = const LinearGradient(
//       colors: [Color(0xFFB3E5FC), Color(0xFF4FC3F7)],
//       begin: Alignment.topCenter,
//       end: Alignment.bottomCenter,
//     ).createShader(Rect.fromLTWH(w * 0.16, h * 0.30, w * 0.68, h * 0.30));
//   canvas.drawRRect(
//     RRect.fromRectAndRadius(
//       Rect.fromLTWH(w * 0.16, h * 0.30, w * 0.68, h * 0.30),
//       const Radius.circular(8),
//     ),
//     windowPaint,
//   );
//   // window divider
//   canvas.drawLine(
//     Offset(w * 0.5, h * 0.30),
//     Offset(w * 0.5, h * 0.60),
//     Paint()
//       ..color = _darken(color, 0.4)
//       ..strokeWidth = 2,
//   );

//   // Wheels
//   final wheelPaint = Paint()..color = const Color(0xFF111111);
//   final rimPaint = Paint()..color = const Color(0xFFBDBDBD);
//   final wheelPositions = [
//     Offset(w * -0.02, h * 0.22),
//     Offset(w * 1.02, h * 0.22),
//     Offset(w * -0.02, h * 0.78),
//     Offset(w * 1.02, h * 0.78),
//   ];
//   for (final p in wheelPositions) {
//     final wheelRect = Rect.fromCenter(
//       center: p,
//       width: w * 0.16,
//       height: h * 0.16,
//     );
//     canvas.drawRRect(
//       RRect.fromRectAndRadius(wheelRect, const Radius.circular(4)),
//       wheelPaint,
//     );
//     canvas.drawCircle(p, w * 0.045, rimPaint);
//   }

//   // Headlights / taillights — position depends on facing direction
//   final frontY = facingUp ? h * 0.06 : h * 0.86;
//   final backY = facingUp ? h * 0.86 : h * 0.06;

//   final headlightPaint = Paint()..color = const Color(0xFFFFF59D);
//   final taillightPaint = Paint()..color = const Color(0xFFE53935);

//   canvas.drawCircle(Offset(w * 0.22, frontY), w * 0.06, headlightPaint);
//   canvas.drawCircle(Offset(w * 0.78, frontY), w * 0.06, headlightPaint);
//   canvas.drawRect(
//     Rect.fromCenter(
//       center: Offset(w * 0.22, backY),
//       width: w * 0.14,
//       height: h * 0.03,
//     ),
//     taillightPaint,
//   );
//   canvas.drawRect(
//     Rect.fromCenter(
//       center: Offset(w * 0.78, backY),
//       width: w * 0.14,
//       height: h * 0.03,
//     ),
//     taillightPaint,
//   );
// }

// Color _darken(Color c, double amount) {
//   final hsl = HSLColor.fromColor(c);
//   return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
// }

// Color _lighten(Color c, double amount) {
//   final hsl = HSLColor.fromColor(c);
//   return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
// }

// class PlayerCar extends PositionComponent
//     with CollisionCallbacks, HasGameReference<CarGame> {
//   PlayerCar() : super(size: Vector2(70, 118), anchor: Anchor.center);

//   @override
//   Future<void> onLoad() async {
//     await add(
//       RectangleHitbox(
//         size: Vector2(size.x * 0.8, size.y * 0.85),
//         position: Vector2(size.x * 0.1, size.y * 0.08),
//       ),
//     );
//   }

//   void moveBy(double dx) {
//     final road = game.road;
//     position.x = (position.x + dx).clamp(
//       road.roadLeft + size.x / 2 + 4,
//       road.roadRight - size.x / 2 - 4,
//     );
//   }

//   @override
//   void render(Canvas canvas) {
//     _drawCarBody(canvas, size, const Color(0xFF1E88E5), facingUp: true);
//   }

//   @override
//   void onCollisionStart(Set<Vector2> points, PositionComponent other) {
//     super.onCollisionStart(points, other);
//     if (other is EnemyCar) {
//       game.triggerGameOver();
//     }
//   }
// }

// class EnemyCar extends PositionComponent
//     with CollisionCallbacks, HasGameReference<CarGame> {
//   final Color color;
//   EnemyCar({required this.color})
//     : super(size: Vector2(70, 118), anchor: Anchor.center);

//   @override
//   Future<void> onLoad() async {
//     await add(
//       RectangleHitbox(
//         size: Vector2(size.x * 0.8, size.y * 0.85),
//         position: Vector2(size.x * 0.1, size.y * 0.08),
//       ),
//     );
//   }

//   @override
//   void update(double dt) {
//     super.update(dt);
//     if (!game.isRunning) return;
//     position.y += game.gameSpeed * dt;
//     if (position.y - size.y / 2 > game.size.y) {
//       removeFromParent();
//     }
//   }

//   @override
//   void render(Canvas canvas) {
//     _drawCarBody(canvas, size, color, facingUp: false);
//   }
// }

// // ============================================================================
// // UI OVERLAYS
// // ============================================================================

// class StartOverlay extends StatelessWidget {
//   final CarGame game;
//   const StartOverlay({super.key, required this.game});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.black.withOpacity(0.55),
//       alignment: Alignment.center,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text(
//             'CAR DODGE',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 42,
//               fontWeight: FontWeight.w900,
//               letterSpacing: 2,
//             ),
//           ),
//           const SizedBox(height: 12),
//           const Text(
//             'Drag left / right to steer.\nDodge the traffic and survive!',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.white70, fontSize: 16),
//           ),
//           const SizedBox(height: 32),
//           _PlayButton(label: 'PLAY', onTap: game.startGame),
//         ],
//       ),
//     );
//   }
// }

// class GameOverOverlay extends StatelessWidget {
//   final CarGame game;
//   const GameOverOverlay({super.key, required this.game});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.black.withOpacity(0.65),
//       alignment: Alignment.center,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text(
//             'GAME OVER',
//             style: TextStyle(
//               color: Colors.redAccent,
//               fontSize: 40,
//               fontWeight: FontWeight.w900,
//               letterSpacing: 2,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Score: ${game.score.toInt()}',
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 32),
//           _PlayButton(label: 'RETRY', onTap: game.startGame),
//         ],
//       ),
//     );
//   }
// }

// class _PlayButton extends StatelessWidget {
//   final String label;
//   final VoidCallback onTap;
//   const _PlayButton({required this.label, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: onTap,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: const Color(0xFF1E88E5),
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//         textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//         elevation: 6,
//       ),
//       child: Text(label),
//     );
//   }
// }

// Devil King: Dungeon Defender
// A trap-based tower-defense game. You play the Devil King defending your
// throne from waves of heroes marching down 3 lanes. Place Spike / Fire /
// Poison traps to stop them. Survive each level's wave to earn gold + a
// throne heal, then face a tougher wave. Every 5th level spawns a Boss.
//
// Everything is drawn procedurally with Canvas/Paint — no image assets.
//
// pubspec.yaml needs:
//   dependencies:
//     flutter:
//       sdk: flutter
//     flame: ^1.18.0
//
// Then just run this as your app's main.dart.
// Devil King: Dungeon Defender
// A trap-based tower-defense game. You play the Devil King defending your
// throne from waves of heroes marching down 3 lanes. Place Spike / Fire /
// Poison traps to stop them. Survive each level's wave to earn gold + a
// throne heal, then face a tougher wave. Every 5th level spawns a Boss.
//
// Everything is drawn procedurally with Canvas/Paint — no image assets.
//
// pubspec.yaml needs:
//   dependencies:
//     flutter:
//       sdk: flutter
//     flame: ^1.18.0
//
// Then just run this as your app's main.dart.
// Devil King: Dungeon Defender
// A trap-based tower-defense game. You play the Devil King defending your
// throne from waves of heroes marching down 3 lanes. Place Spike / Fire /
// Poison traps to stop them. Survive each level's wave to earn gold + a
// throne heal, then face a tougher wave. Every 5th level spawns a Boss.
//
// Everything is drawn procedurally with Canvas/Paint — no image assets.
//
// pubspec.yaml needs:
//   dependencies:
//     flutter:
//       sdk: flutter
//     flame: ^1.18.0
//
// Then just run this as your app's main.dart.

import 'dart:async';
import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: DevilKingGame()));
}

// ---------------------------------------------------------------------------
// Layout constants (virtual resolution, portrait)
// ---------------------------------------------------------------------------
const double kWorldW = 480;
const double kWorldH = 800;
const double kLaneTop = 110;
const double kThroneY = 650; // y at which a hero "reaches" the throne
const double kBottomBarY = 754;

const List<double> kLaneX = [80, 240, 400];
const List<double> kSlotYs = [190, 320, 450, 580];

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------
enum HeroType { swordsman, knight, rogue, boss }

enum TrapType { spikes, fire, poison }

enum GameState { playing, levelComplete, gameOver }

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------
class HeroStats {
  final double hp;
  final double speed;
  final double dmg;
  final double radius;
  final Color color;
  final int reward;
  const HeroStats(
    this.hp,
    this.speed,
    this.dmg,
    this.radius,
    this.color,
    this.reward,
  );
}

HeroStats baseStatsFor(HeroType type) => switch (type) {
  HeroType.swordsman => const HeroStats(30, 42, 10, 14, Color(0xFF6B8CAE), 5),
  HeroType.knight => const HeroStats(75, 26, 20, 16, Color(0xFF9AA0A6), 10),
  HeroType.rogue => const HeroStats(18, 72, 8, 12, Color(0xFF4CAF6D), 6),
  HeroType.boss => const HeroStats(420, 20, 50, 26, Color(0xFF6A1B9A), 120),
};

class TrapStats {
  final int cost;
  final double cooldown;
  final double damage;
  final double range;
  final Color color;
  final String label;
  const TrapStats(
    this.cost,
    this.cooldown,
    this.damage,
    this.range,
    this.color,
    this.label,
  );
}

TrapStats statsForTrap(TrapType t) => switch (t) {
  TrapType.spikes => const TrapStats(
    20,
    1.0,
    14,
    46,
    Color(0xFFB0B0B0),
    'Spikes',
  ),
  TrapType.fire => const TrapStats(45, 2.5, 9, 95, Color(0xFFFF7043), 'Fire'),
  TrapType.poison => const TrapStats(
    35,
    2.0,
    5,
    50,
    Color(0xFF66BB6A),
    'Poison',
  ),
};

// ---------------------------------------------------------------------------
// Game / World
// ---------------------------------------------------------------------------
class DevilKingGame extends FlameGame {
  DevilKingGame() : super(world: DungeonWorld());

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(kWorldW, kWorldH),
    );
    await super.onLoad();
  }

  @override
  Color backgroundColor() => const Color(0xFF0A0605);
}

class DungeonWorld extends World {
  int gold = 100;
  double throneHp = 100;
  double maxThroneHp = 100;
  int level = 1;

  int heroesToSpawn = 0;
  int heroesSpawned = 0;
  double spawnTimer = 0;
  double spawnInterval = 1.2;
  List<HeroType> currentWaveQueue = [];

  final List<HeroComponent> heroes = [];
  final List<TrapSlotComponent> slots = [];
  TrapType selectedTrap = TrapType.spikes;
  GameState state = GameState.playing;
  final Random rng = Random();

  late TextComponent goldText;
  late TextComponent levelText;
  late TextComponent waveText;
  late HpBarComponent hpBar;
  OverlayPanelComponent? overlay;

  @override
  Future<void> onLoad() async {
    add(BackgroundComponent());
    add(LaneDividersComponent());

    for (int lane = 0; lane < kLaneX.length; lane++) {
      for (final sy in kSlotYs) {
        final slot = TrapSlotComponent(
          lane: lane,
          position: Vector2(kLaneX[lane], sy),
        );
        slots.add(slot);
        add(slot);
      }
    }

    add(ThroneComponent(position: Vector2(kLaneX[1], kThroneY + 45)));

    goldText = _hudText('Gold: $gold', Vector2(16, 14));
    levelText = _hudText('Level $level', Vector2(16, 40));
    waveText = _hudText('', Vector2(16, 66));
    add(goldText);
    add(levelText);
    add(waveText);

    hpBar = HpBarComponent(position: Vector2(250, 24));
    add(hpBar);

    add(
      TrapButtonComponent(
        type: TrapType.spikes,
        position: Vector2(10, kBottomBarY),
      ),
    );
    add(
      TrapButtonComponent(
        type: TrapType.fire,
        position: Vector2(170, kBottomBarY),
      ),
    );
    add(
      TrapButtonComponent(
        type: TrapType.poison,
        position: Vector2(330, kBottomBarY),
      ),
    );

    startLevel();
  }

  TextComponent _hudText(String text, Vector2 pos) {
    return TextComponent(
      text: text,
      position: pos,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void startLevel() {
    heroesSpawned = 0;
    currentWaveQueue = _buildWave(level);
    heroesToSpawn = currentWaveQueue.length;
    spawnTimer = 0;
    spawnInterval = max(0.45, 1.2 - level * 0.03);
    state = GameState.playing;
  }

  List<HeroType> _buildWave(int lvl) {
    final list = <HeroType>[];
    final count = 5 + lvl * 2;
    for (int i = 0; i < count; i++) {
      final r = rng.nextDouble();
      if (lvl >= 3 && r < 0.15) {
        list.add(HeroType.knight);
      } else if (lvl >= 2 && r < 0.35) {
        list.add(HeroType.rogue);
      } else {
        list.add(HeroType.swordsman);
      }
    }
    if (lvl % 5 == 0) {
      list.add(HeroType.boss);
    }
    return list;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state == GameState.playing) {
      _handleSpawning(dt);
      _checkLevelComplete();
    }
    _updateHud();
  }

  void _handleSpawning(double dt) {
    if (heroesSpawned >= heroesToSpawn) return;
    spawnTimer -= dt;
    if (spawnTimer <= 0) {
      spawnTimer = spawnInterval;
      final type = currentWaveQueue[heroesSpawned];
      heroesSpawned++;
      _spawnHero(type, rng.nextInt(3));
    }
  }

  void _spawnHero(HeroType type, int lane) {
    final base = baseStatsFor(type);
    final hpScale = 1 + 0.15 * (level - 1);
    final dmgScale = 1 + 0.08 * (level - 1);
    final hero = HeroComponent(
      world: this,
      type: type,
      lane: lane,
      maxHp: base.hp * hpScale,
      speed: base.speed,
      throneDamage: base.dmg * dmgScale,
      color: base.color,
      radius: base.radius,
      reward: base.reward,
      position: Vector2(kLaneX[lane], kLaneTop),
    );
    heroes.add(hero);
    add(hero);
  }

  void _checkLevelComplete() {
    if (heroesSpawned >= heroesToSpawn && heroes.isEmpty) {
      _completeLevel();
    }
  }

  void _completeLevel() {
    state = GameState.levelComplete;
    final reward = 30 + level * 10;
    gold += reward;
    throneHp = min(maxThroneHp, throneHp + 15);
    overlay = OverlayPanelComponent(
      title: 'Level $level Cleared!',
      subtitle: '+$reward Gold  •  +15 Throne HP',
      buttonLabel: 'Continue',
      onTap: () {
        remove(overlay!);
        overlay = null;
        level++;
        startLevel();
      },
    );
    add(overlay!);
  }

  void heroReachedThrone(HeroComponent hero) {
    throneHp -= hero.throneDamage;
    _removeHero(hero);
    if (throneHp <= 0) {
      throneHp = 0;
      _gameOver();
    }
  }

  void heroDied(HeroComponent hero) {
    gold += hero.reward;
    _removeHero(hero);
  }

  void _removeHero(HeroComponent hero) {
    heroes.remove(hero);
    hero.removeFromParent();
  }

  void _gameOver() {
    state = GameState.gameOver;
    overlay = OverlayPanelComponent(
      title: 'Game Over',
      subtitle: 'The dungeon fell at Level $level',
      buttonLabel: 'Restart',
      onTap: _restart,
    );
    add(overlay!);
  }

  void _restart() {
    for (final h in List<HeroComponent>.from(heroes)) {
      _removeHero(h);
    }
    for (final s in slots) {
      s.clearTrap();
    }
    if (overlay != null) {
      remove(overlay!);
      overlay = null;
    }
    gold = 100;
    throneHp = 100;
    maxThroneHp = 100;
    level = 1;
    startLevel();
  }

  bool trySpendGold(int amount) {
    if (gold >= amount) {
      gold -= amount;
      return true;
    }
    return false;
  }

  void _updateHud() {
    goldText.text = 'Gold: $gold';
    levelText.text = 'Level $level';
    final remaining = (heroesToSpawn - heroesSpawned) + heroes.length;
    waveText.text = 'Heroes left: $remaining';
    hpBar.value = throneHp / maxThroneHp;
  }
}

// ---------------------------------------------------------------------------
// Background & lanes
// ---------------------------------------------------------------------------
class BackgroundComponent extends PositionComponent {
  final Random _r = Random(7);
  final List<Rect> _tiles = [];
  final List<Color> _tileColors = [];
  late List<Path> _cracks;

  BackgroundComponent()
    : super(position: Vector2.zero(), size: Vector2(kWorldW, kWorldH));

  @override
  Future<void> onLoad() async {
    const tileSize = 40.0;
    for (double y = 0; y < kWorldH; y += tileSize) {
      for (double x = 0; x < kWorldW; x += tileSize) {
        _tiles.add(Rect.fromLTWH(x, y, tileSize, tileSize));
        final shade = 20 + _r.nextInt(12);
        _tileColors.add(Color.fromARGB(255, shade + 10, shade, shade));
      }
    }
    _cracks = List.generate(4, (_) => _makeCrack());
  }

  Path _makeCrack() {
    final path = Path();
    double x = _r.nextDouble() * kWorldW;
    double y = _r.nextDouble() * kWorldH;
    path.moveTo(x, y);
    for (int i = 0; i < 6; i++) {
      x = (x + (_r.nextDouble() - 0.5) * 90).clamp(0, kWorldW);
      y = (y + (_r.nextDouble() - 0.5) * 90).clamp(0, kWorldH);
      path.lineTo(x, y);
    }
    return path;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();
    for (int i = 0; i < _tiles.length; i++) {
      paint.color = _tileColors[i];
      canvas.drawRect(_tiles[i], paint);
    }
    final glow = Paint()
      ..color = const Color(0xFFFF5722).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final line = Paint()
      ..color = const Color(0xFFFF8A50).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final c in _cracks) {
      canvas.drawPath(c, glow);
      canvas.drawPath(c, line);
    }
  }
}

class LaneDividersComponent extends PositionComponent {
  @override
  void render(Canvas canvas) {
    final tint = Paint()..color = Colors.black.withOpacity(0.15);
    for (final lx in kLaneX) {
      canvas.drawRect(
        Rect.fromLTWH(lx - 70, kLaneTop - 10, 140, kThroneY - kLaneTop + 20),
        tint,
      );
    }
    final divider = Paint()
      ..color = Colors.orange.withOpacity(0.25)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(160, kLaneTop - 10),
      Offset(160, kThroneY + 10),
      divider,
    );
    canvas.drawLine(
      Offset(320, kLaneTop - 10),
      Offset(320, kThroneY + 10),
      divider,
    );
  }
}

// ---------------------------------------------------------------------------
// Throne / Devil King
// ---------------------------------------------------------------------------
class ThroneComponent extends PositionComponent {
  double _t = 0;
  ThroneComponent({required Vector2 position})
    : super(
        position: position,
        size: Vector2(220, 140),
        anchor: Anchor.topCenter,
      );

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final bob = sin(_t * 1.5) * 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 90, 200, 40),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF2B1B12),
    );

    final chairRect = Rect.fromLTWH(60, 20 + bob, 100, 80);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chairRect, const Radius.circular(10)),
      Paint()..color = const Color(0xFF3A0D0D),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chairRect, const Radius.circular(10)),
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawOval(
      Rect.fromLTWH(75, 30 + bob, 70, 60),
      Paint()..color = const Color(0xFFB71C1C),
    );

    final hornPaint = Paint()..color = const Color(0xFF1B1B1B);
    canvas.drawPath(
      Path()
        ..moveTo(85, 25 + bob)
        ..lineTo(78, 5 + bob)
        ..lineTo(95, 22 + bob)
        ..close(),
      hornPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(135, 25 + bob)
        ..lineTo(142, 5 + bob)
        ..lineTo(125, 22 + bob)
        ..close(),
      hornPaint,
    );

    final eyePaint = Paint()..color = const Color(0xFFFFEB3B);
    canvas.drawCircle(Offset(100, 50 + bob), 4, eyePaint);
    canvas.drawCircle(Offset(120, 50 + bob), 4, eyePaint);
  }
}

// ---------------------------------------------------------------------------
// Heroes
// ---------------------------------------------------------------------------
class PoisonStack {
  double remaining;
  final double dps;
  PoisonStack(this.remaining, this.dps);
}

class HeroComponent extends PositionComponent {
  final DungeonWorld world;
  final HeroType type;
  final int lane;
  final double maxHp;
  double hp;
  final double speed;
  final double throneDamage;
  final Color color;
  final double radius;
  final int reward;
  double _t = 0;
  bool dead = false;
  final List<PoisonStack> poison = [];

  HeroComponent({
    required this.world,
    required this.type,
    required this.lane,
    required this.maxHp,
    required this.speed,
    required this.throneDamage,
    required this.color,
    required this.radius,
    required this.reward,
    required Vector2 position,
  }) : hp = maxHp,
       super(
         position: position,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       );

  void applyDamage(double amount) {
    if (dead) return;
    hp -= amount;
    if (hp <= 0) {
      dead = true;
      world.heroDied(this);
    }
  }

  void applyPoison(double dps, double duration) {
    if (dead) return;
    if (poison.length < 3) {
      poison.add(PoisonStack(duration, dps));
    } else {
      poison[0].remaining = duration;
    }
  }

  @override
  void update(double dt) {
    if (world.state != GameState.playing || dead) return;
    _t += dt;
    position.y += speed * dt;

    if (poison.isNotEmpty) {
      double totalDps = 0;
      for (final p in poison) {
        totalDps += p.dps;
        p.remaining -= dt;
      }
      poison.removeWhere((p) => p.remaining <= 0);
      hp -= totalDps * dt;
      if (hp <= 0) {
        dead = true;
        world.heroDied(this);
        return;
      }
    }

    if (position.y >= kThroneY) {
      dead = true;
      world.heroReachedThrone(this);
    }
  }

  @override
  void render(Canvas canvas) {
    final bob = sin(_t * 10) * 2;
    final bodyPaint = Paint()..color = color;
    final legPaint = Paint()..color = color.withOpacity(0.7);
    final legOffset = sin(_t * 12) * 3;

    canvas.drawRect(
      Rect.fromLTWH(radius - 6, radius * 2 - 6, 4, 8 + legOffset),
      legPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(radius + 2, radius * 2 - 6, 4, 8 - legOffset),
      legPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(radius, radius + 4 + bob),
          width: radius * 1.4,
          height: radius * 1.3,
        ),
        const Radius.circular(4),
      ),
      bodyPaint,
    );
    canvas.drawCircle(
      Offset(radius, radius - radius * 0.5 + bob),
      radius * 0.5,
      bodyPaint,
    );

    if (type == HeroType.boss) {
      canvas.drawRect(
        Rect.fromLTWH(radius - 8, radius - radius * 1.0 + bob, 16, 5),
        Paint()..color = Colors.amberAccent,
      );
    }

    final barW = radius * 2.2;
    canvas.drawRect(
      Rect.fromLTWH(-0.1 * radius, -10, barW, 4),
      Paint()..color = Colors.black54,
    );
    canvas.drawRect(
      Rect.fromLTWH(-0.1 * radius, -10, barW * (hp / maxHp).clamp(0, 1), 4),
      Paint()..color = Colors.redAccent,
    );

    if (poison.isNotEmpty) {
      canvas.drawCircle(
        Offset(radius * 2 - 2, -6),
        3,
        Paint()..color = Colors.greenAccent,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Trap slots & traps
// ---------------------------------------------------------------------------
class TrapSlotComponent extends PositionComponent with TapCallbacks {
  final int lane;
  TrapComponent? trap;

  TrapSlotComponent({required this.lane, required Vector2 position})
    : super(position: position, size: Vector2.all(56), anchor: Anchor.center);

  DungeonWorld get world => parent as DungeonWorld;

  void clearTrap() {
    trap?.removeFromParent();
    trap = null;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (world.state != GameState.playing || trap != null) return;
    final stats = statsForTrap(world.selectedTrap);
    if (world.trySpendGold(stats.cost)) {
      trap = TrapComponent(type: world.selectedTrap, slot: this);
      parent!.add(trap!);
    }
  }

  @override
  void render(Canvas canvas) {
    if (trap != null) return;
    final canAfford = world.gold >= statsForTrap(world.selectedTrap).cost;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 - 2,
      Paint()
        ..color = (canAfford ? Colors.greenAccent : Colors.redAccent)
            .withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final plusPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2;
    final cx = size.x / 2, cy = size.y / 2;
    canvas.drawLine(Offset(cx - 6, cy), Offset(cx + 6, cy), plusPaint);
    canvas.drawLine(Offset(cx, cy - 6), Offset(cx, cy + 6), plusPaint);
  }
}

class TrapComponent extends PositionComponent {
  final TrapType type;
  final TrapSlotComponent slot;
  double cooldown = 0;
  double flash = 0;
  double _t = 0;

  TrapComponent({required this.type, required this.slot})
    : super(
        position: slot.position.clone(),
        size: Vector2.all(48),
        anchor: Anchor.center,
      );

  DungeonWorld get world => slot.world;
  int get lane => slot.lane;

  @override
  void update(double dt) {
    _t += dt;
    if (flash > 0) flash -= dt;
    if (world.state != GameState.playing) return;
    cooldown -= dt;
    if (cooldown <= 0 && _tryTrigger()) {
      cooldown = statsForTrap(type).cooldown;
      flash = 0.3;
    }
  }

  bool _tryTrigger() {
    final stats = statsForTrap(type);
    final laneHeroes = world.heroes
        .where(
          (h) =>
              h.lane == lane &&
              (h.position.y - position.y).abs() <= stats.range,
        )
        .toList();
    if (laneHeroes.isEmpty) return false;

    switch (type) {
      case TrapType.spikes:
        laneHeroes.sort((a, b) => b.position.y.compareTo(a.position.y));
        laneHeroes.first.applyDamage(stats.damage);
        return true;
      case TrapType.poison:
        laneHeroes.sort((a, b) => b.position.y.compareTo(a.position.y));
        laneHeroes.first.applyPoison(stats.damage, 5);
        return true;
      case TrapType.fire:
        for (final h in laneHeroes) {
          h.applyDamage(stats.damage);
        }
        return true;
    }
  }

  @override
  void render(Canvas canvas) {
    final stats = statsForTrap(type);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 4, 40, 40),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF2A2119),
    );

    switch (type) {
      case TrapType.spikes:
        final p = Paint()..color = stats.color;
        for (int i = 0; i < 3; i++) {
          final x = 12.0 + i * 10;
          canvas.drawPath(
            Path()
              ..moveTo(x, 36)
              ..lineTo(x + 5, 12)
              ..lineTo(x + 10, 36)
              ..close(),
            p,
          );
        }
        break;
      case TrapType.fire:
        final flick = sin(_t * 14) * 3;
        final flame = Path()
          ..moveTo(24, 36)
          ..quadraticBezierTo(6, 26, 14, 10 + flick)
          ..quadraticBezierTo(20, 20, 24, 6)
          ..quadraticBezierTo(28, 20, 34, 10 + flick)
          ..quadraticBezierTo(42, 26, 24, 36)
          ..close();
        canvas.drawPath(
          flame,
          Paint()..color = Colors.redAccent.withOpacity(0.85),
        );
        canvas.save();
        canvas.translate(6, 10);
        canvas.scale(0.55);
        canvas.drawPath(
          flame,
          Paint()..color = Colors.yellowAccent.withOpacity(0.9),
        );
        canvas.restore();
        break;
      case TrapType.poison:
        final pulse = (sin(_t * 4) + 1) / 2;
        canvas.drawCircle(
          const Offset(24, 24),
          12 + pulse * 3,
          Paint()..color = stats.color.withOpacity(0.5 + 0.3 * pulse),
        );
        canvas.drawCircle(
          const Offset(18, 20),
          4,
          Paint()..color = Colors.lightGreenAccent,
        );
        canvas.drawCircle(
          const Offset(28, 28),
          3,
          Paint()..color = Colors.lightGreenAccent,
        );
        break;
    }

    if (flash > 0) {
      canvas.drawCircle(
        const Offset(24, 24),
        stats.range * (1 - flash / 0.3),
        Paint()
          ..color = stats.color.withOpacity((flash / 0.3) * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// HUD widgets
// ---------------------------------------------------------------------------
class HpBarComponent extends PositionComponent {
  double value = 1.0;

  HpBarComponent({required Vector2 position})
    : super(position: position, size: Vector2(210, 18));

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black45,
    );
    final c = value.clamp(0, 1);
    final color = Color.lerp(Colors.red, Colors.greenAccent, c.toDouble())!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x * c, size.y),
        const Radius.circular(4),
      ),
      Paint()..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(4),
      ),
      Paint()
        ..color = Colors.white38
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Throne HP',
        style: TextStyle(color: Colors.white, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(4, -14));
  }
}

class TrapButtonComponent extends PositionComponent with TapCallbacks {
  final TrapType type;

  TrapButtonComponent({required this.type, required Vector2 position})
    : super(position: position, size: Vector2(140, 38));

  DungeonWorld get world => parent as DungeonWorld;

  @override
  void onTapUp(TapUpEvent event) => world.selectedTrap = type;

  @override
  void render(Canvas canvas) {
    final stats = statsForTrap(type);
    final selected = world.selectedTrap == type;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(6),
      ),
      Paint()
        ..color = selected
            ? stats.color.withOpacity(0.9)
            : const Color(0xFF241713),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(6),
      ),
      Paint()
        ..color = selected ? Colors.white : Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2 : 1,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '${stats.label}\n${stats.cost}g',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x);
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
  }
}

// ---------------------------------------------------------------------------
// Overlay (level complete / game over)
// ---------------------------------------------------------------------------
class OverlayPanelComponent extends PositionComponent with TapCallbacks {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;
  Rect buttonRect = Rect.zero;

  OverlayPanelComponent({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  }) : super(position: Vector2.zero(), size: Vector2(kWorldW, kWorldH));

  @override
  void onTapUp(TapUpEvent event) {
    final p = event.localPosition;
    if (buttonRect.contains(Offset(p.x, p.y))) onTap();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.black.withOpacity(0.72),
    );
    final panelRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: 320,
      height: 200,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(12)),
      Paint()..color = const Color(0xFF241713),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(12)),
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final titleTp = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: panelRect.width - 20);
    titleTp.paint(
      canvas,
      Offset(panelRect.center.dx - titleTp.width / 2, panelRect.top + 24),
    );

    final subTp = TextPainter(
      text: TextSpan(
        text: subtitle,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: panelRect.width - 30);
    subTp.paint(
      canvas,
      Offset(panelRect.center.dx - subTp.width / 2, panelRect.top + 70),
    );

    buttonRect = Rect.fromCenter(
      center: Offset(panelRect.center.dx, panelRect.bottom - 40),
      width: 160,
      height: 44,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, const Radius.circular(8)),
      Paint()..color = const Color(0xFFB71C1C),
    );
    final btnTp = TextPainter(
      text: TextSpan(
        text: buttonLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    btnTp.paint(
      canvas,
      Offset(
        buttonRect.center.dx - btnTp.width / 2,
        buttonRect.center.dy - btnTp.height / 2,
      ),
    );
  }
}
