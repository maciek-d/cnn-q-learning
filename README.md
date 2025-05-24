# Convolutional Q-Learning Agent for Game Boy Advance

This project implements a **Convolutional Q-learning agent** with **experience replay**, designed to learn directly from pixel input while playing **Game Boy Advance (GBA)** games via emulator scripting.

> ⚠️ Note: This project may require some setup effort. The Lua scripts included are functional but slightly outdated, and you may need to tweak them depending on your emulator setup and game configuration.


## 🎮 Game Demos

#### **Super Mario Bros. (GBA)**  
[Watch on YouTube](https://youtu.be/ER8vTr8qgok)  
[![Super Mario Bros.](https://img.youtube.com/vi/ER8vTr8qgok/0.jpg)](https://youtu.be/ER8vTr8qgok)

---

#### **Super Mario World (GBA)**  
[Watch on YouTube](https://youtu.be/8WXnK6SlbTY)  
[![Super Mario World](https://img.youtube.com/vi/8WXnK6SlbTY/0.jpg)](https://youtu.be/8WXnK6SlbTY)

---

#### **Iridion 3D (GBA)**  
[Watch on YouTube](https://youtu.be/qfTpp6OrO1c)  
[![Iridion 3D](https://img.youtube.com/vi/qfTpp6OrO1c/0.jpg)](https://youtu.be/qfTpp6OrO1c)

## 🧠 Core Features

- Deep Q-Network with convolutional layers
- Experience replay buffer for stabilizing learning
- Image preprocessing with grayscale conversion and normalization
- Game state captured through emulator screenshots
- Uses **Lua scripting** for bidirectional communication with the emulator

## 🛠 Requirements

- [**FCEUX Emulator**](http://www.fceux.com/web/home.html)
  - Must be positioned in the **top corner of the screen**
- **Python 3**
- `skimage`, `numpy`, and other common Python packages
- Ability to run **Lua scripts** in FCEUX

## 🚀 How it Works

1. The emulator renders game frames which are captured and preprocessed.
2. A deep Q-learning model receives the game state and selects an action.
3. The chosen action is written to a file that the Lua script reads inside the emulator.
4. The model updates based on rewards derived from in-game score changes.
5. The reward function encourages progress and penalizes death or regress.

---

Feel free to fork, explore, or build on top of this!

