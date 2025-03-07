import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

void main() {
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame {
  late SpriteAnimationComponent character;
  TiledComponent? map;
  late JoystickComponent joystick;
  late SpriteAnimation idleAnimation;
  late SpriteAnimation walkAnimation;
  late Vector2 exitPosition;

  String currentMap = "maps/map_level1.tmx";
  final double tileSize = 32; // Tiled'daki her bir tile boyutu (32x32 gibi)

  @override
  Future<void> onLoad() async {
    await loadMap(currentMap);
  }

  Future<void> loadMap(String mapPath) async {
    if (map != null) {
      remove(map!);
    }

    print("🔄 Yeni harita yükleniyor: $mapPath");
    map = await TiledComponent.load(mapPath, Vector2.all(tileSize));
    add(map!);
    print("✅ Harita yüklendi: $mapPath");

    final ObjectGroup? exitLayer = map?.tileMap.getLayer<ObjectGroup>('Objects');

    if (exitLayer == null) {
      print("❌ HATA: 'Objects' katmanı bulunamadı!");
    } else {
      print("✅ 'Objects' katmanı bulundu.");
    }

    final exitObject = exitLayer?.objects.firstWhereOrNull(
          (o) => o.name == 'exit_zone',
    );

    if (exitObject != null) {
      final double mapWidth = map!.tileMap.map.width * tileSize;
      final double mapHeight = map!.tileMap.map.height * tileSize;

      print("📌 Tiled'daki exit_zone koordinatları: X = ${exitObject.x}, Y = ${exitObject.y}");
      print("📌 Harita genişliği: $mapWidth, yüksekliği: $mapHeight");

      exitPosition = Vector2(
          exitObject.x + (5 * tileSize), // X ekseninde sağa kaydır
          (mapHeight - exitObject.y) + (5 * tileSize) // Y ekseninde aşağı kaydır
      );

      print("✅ Güncellenmiş exitPosition: $exitPosition");
    } else {
      print("❌ HATA: exit_zone bulunamadı!");
      exitPosition = Vector2(321, 137); // Varsayılan değer
    }




    // 📌 Animasyonları yükle (Idle ve Yürüme)
    final idleFrames = await Future.wait([
      loadSprite('characters/Female adventurer/character_femaleAdventurer_idle.png'),
      loadSprite('characters/Female adventurer/character_femaleAdventurer_idle.png'),
    ]);

    final walkFrames = await Future.wait([
      loadSprite('characters/Female adventurer/character_femaleAdventurer_walk0.png'),
      loadSprite('characters/Female adventurer/character_femaleAdventurer_walk1.png'),
      loadSprite('characters/Female adventurer/character_femaleAdventurer_walk2.png'),
      loadSprite('characters/Female adventurer/character_femaleAdventurer_walk3.png'),
      loadSprite('characters/Female adventurer/character_femaleAdventurer_walk4.png'),
      loadSprite('characters/Female adventurer/character_femaleAdventurer_walk5.png'),
      loadSprite('characters/Female adventurer/character_femaleAdventurer_walk6.png'),
      loadSprite('characters/Female adventurer/character_femaleAdventurer_walk7.png'),
    ]);

    // 🔥 Animasyonları oluştur
    idleAnimation = SpriteAnimation.spriteList(idleFrames, stepTime: 0.5);
    walkAnimation = SpriteAnimation.spriteList(walkFrames, stepTime: 0.1);

    // 🎭 Karakteri oluştur
    character = SpriteAnimationComponent()
      ..animation = idleAnimation
      ..size = Vector2(64, 64)
      ..position = Vector2(size.x / 2, size.y / 2);

    add(character);

    // 🎮 Joystick bileşenini oluştur
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 15, paint: Paint()..color = Colors.blue),
      background: CircleComponent(radius: 50, paint: Paint()..color = Colors.grey.withOpacity(0.5)),
      margin: const EdgeInsets.only(left: 30, bottom: 30),
    );

    add(joystick);
  }

  @override
  void update(double dt) {
    super.update(dt);

    double distance = (character.position - exitPosition).length;
    print("📏 Karakter çıkış noktasına mesafe: $distance");

    if (joystick.delta != Vector2.zero()) {
      character.animation = walkAnimation;
      character.position += joystick.delta * 3 * dt;
    } else {
      character.animation = idleAnimation;
    }

    // 📌 Çıkış noktasına ulaştı mı?
    if (distance < 20) {
      print("✅ Karakter çıkış noktasına ulaştı! Yeni haritaya geçiliyor...");
      changeMap("maps/map_level_2.tmx");
    }
  }

  void changeMap(String newMap) {
    print("🌍 Harita değiştiriliyor: $newMap");
    currentMap = newMap;
    loadMap(currentMap);
  }
}
