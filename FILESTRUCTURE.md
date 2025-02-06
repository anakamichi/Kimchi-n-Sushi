# 📂 Godot 2D Game Development - File Structure Rules

To maintain a clean and manageable project, we follow a **three-folder structure**:

```
res://
│── 📂 scenes/   # Scene files
│── 📂 scripts/  # Script files
│── 📂 assets/   # Assets (sprites, sounds, fonts, etc.)
```

---

## **📂 `scenes/` (Scene Files)**
All **`.tscn`** files go into this folder. Subfolders help categorize different types of scenes.

```
scenes/
│── main/        # Main menu, title screen
│── game/        # Main game scenes
│── ui/          # UI elements (HUD, pause menu)
│── characters/  # Player and enemy character scenes
│── levels/      # Level and stage scenes
```

### **Example Files:**
- `scenes/main/MainMenu.tscn`
- `scenes/game/GameScene.tscn`
- `scenes/ui/PauseMenu.tscn`
- `scenes/characters/Player.tscn`
- `scenes/characters/Enemy.tscn`
- `scenes/levels/Level1.tscn`

---

## **📂 `scripts/` (Script Files)**
All **`.gd`** script files go into this folder. Scripts are categorized to match their corresponding scenes.

```
scripts/
│── main/        # Scripts for main menu and title screen
│── game/        # Core game logic scripts
│── ui/          # Scripts for UI elements
│── characters/  # Player and enemy scripts
│── levels/      # Scripts related to levels and stages
```

### **Example Files:**
- `scripts/main/MainMenu.gd`
- `scripts/game/GameScene.gd`
- `scripts/ui/PauseMenu.gd`
- `scripts/characters/Player.gd`
- `scripts/characters/Enemy.gd`
- `scripts/levels/Level1.gd`

### **Rules:**
- Each scene should have a corresponding script (e.g., `scenes/game/GameScene.tscn` → `scripts/game/GameScene.gd`).
- Script file names should match the scene names (e.g., `Player.tscn` → `Player.gd`).
- Use subfolders that align with `scenes/` structure.

---

## **📂 `assets/` (Game Assets)**
All **sprites, sounds, fonts, and other assets** are stored here, categorized by type.

```
assets/
│── sprites/     # Sprites (images)
│   ├── characters/  # Player and enemies
│   ├── environment/ # Backgrounds and tilesets
│── audio/       # Audio files (BGM, sound effects)
│   ├── music/   # Background music
│   ├── sfx/     # Sound effects
│── fonts/       # Fonts
│── shaders/     # Shaders (if needed)
```

### **Example Files:**
- `assets/sprites/characters/player.png`
- `assets/sprites/environment/background.png`
- `assets/audio/music/bgm_main.ogg`
- `assets/audio/sfx/jump.wav`
- `assets/fonts/game_font.tres`

### **Rules:**
- Organize assets by **type**, not by scene.
- Use **clear file names** (e.g., `player_idle.png`, `bg_forest.png`).
- **Remove unused assets** to keep the project clean.

---

## **📌 Summary of the Rules**
✅ **Scenes** go in `scenes/`
✅ **Scripts** go in `scripts/` (matching scene structure)
✅ **Assets** go in `assets/` (organized by type, not scene)

This **three-folder structure** keeps the project simple, organized, and easy to manage for team collaboration! 🚀
