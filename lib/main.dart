import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: FlameGame(world: MyWorld())));
}

class MyWorld extends World {
  @override
  Future<void> onLoad() async {
    add(Player(position: Vector2(0, 0)));
    return super.onLoad();
  }
}

class Player extends SpriteComponent with TapCallbacks {
  Player({super.position})
    : super(size: Vector2.all(200), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('player.png');
    return super.onLoad();
  }

  @override
  void onTapUp(TapUpEvent event) {
    size += Vector2.all(20);
    super.onTapUp(event);
  }

  @override
  void onTapDown(TapDownEvent event) {
    size -= Vector2.all(20);
    super.onTapDown(event);
  }
}
