# 🎨 Skribbl Clone

Multiplayer drawing and guessing game similar to Skribbl.io

Players can create rooms, join rooms via room code and play in real-time drawing and guessing game with many players.

Application also features **Quick Join** that allows user to join ongoing public game without using any room code.

## 🚀 Live Application

**Live Link:**
https://skribbl-game-sepia.vercel.app/

**GitHub Link:**
https://github.com/abhayguptadev/skribbl_clone

## ✨ Features

### Core Features

* Create game room
* Join game via room code
* Real-time multiplayer gameplay
* Drawing and guessing
* Multiple game rounds
* Turn-based gameplay
* Word selection
* Round timer
* Player scoring
* Round results
* Player avatars
* Public/Private rooms
* Real-time Web Socket Communication
* Quick Join for ongoing public games

### Game Settings

* Maximum players
* Rounds number
* Drawing time
* Words choices number
* Hints
* Word categories
* Custom words

### Multiplayer

* Real-time player presence
* Real-time game state synchronization
* Turn management
* Drawing synchronization
* Score synchronization
* Round state management

## ⚡ Quick Join

Quick Join provides an option for a player to join an existing **public running game** without providing any room code.

### Process

```text
Home Screen
     ↓
Input Name + Choose Avatar
     ↓
Quick Join
     ↓
Backend checks running public games
     ↓
Running game found
     ↓
Player joins the game
     ↓
Game Screen
```

The backend finds an appropriate running game in which a player can be added.

When there are no running games that can be used by a player, the app will show the following message:

```text
No running game available.
```

## 🏗️ Architecture

This application is built using a Flutter frontend and a Django backend.

```text
Skribbl Clone
│
├── Flutter Frontend
│   ├── Home Screen
│   ├── Create Room
│   ├── Join Room
│   ├── Quick Join
│   ├── Game Screen
│   └── Game State Management
│
└── Django Backend
    ├── REST API
    ├── Websocket Communication
    ├── Room Management
    ├── Game Manager
    ├── Scoring
    └── Word Management
```

## 📁 Backend Structure

```text
backend/
│
├── config/
│   ├── asgi.py
│   ├── routing.py
│   ├── settings.py
│   └── urls.py
│
├── game/
│   ├── db_service.py
│   ├── game_manager.py
│   ├── scoring.py
│   └── word_manager.py
│
├── rooms/
│   ├── consumers.py
│   ├── models.py
│   ├── serializers.py
│   ├── urls.py
│   └── views.py
│
├── docker-compose.yml
├── manage.py
└── requirements.txt
```

## 🧩 Backend Components

### Game Manager

`game_manager.py` is responsible for managing game states, rooms, players, game phases and turns.

### WebSocket Consumer

`consumers.py` is used to manage real-time communication between the players and the backend using Django Channels and Websockets.

### Scoring

`scoring.py` is responsible for game score calculations.

### Word Manager

`word_manager.py` manages the word pools and other word related logic.

### Database Service

`db_service.py` is responsible for providing database access using **SQLite through Django ORM**.

It also handles persistence of rooms and completed game sessions.

## 🛠️ Tech Stack

### Frontend

* Flutter
* Dart
* Provider
* HTTP
* WebSockets

### Backend

* Python
* Django
* Django REST Framework
* Django Channels
* WebSockets

### Database

* SQLite
* Django ORM

### Version Control

* Git
* GitHub


## 🔌 API Endpoints

### Create Room

```http
POST /api/rooms/
```

Creates a new game room.
### Join Room

```http
POST /api/rooms/join/
```

Join an existing room using a room code.

### Quick Join

```http
POST /api/rooms/quick-join/
```

Quickly join an available running public game without the need for a room code.

### Room Details

```http
GET /api/rooms/<room_code>/
```

Provides the public state of the room.

### Word List

```http
GET /api/words/
```

Provides available word categories and sample words.

### Health Check

```http
GET /api/health/
```

Checks the status of the backend service.

## 🔄 Game Flow

```text
Player
  ↓
Home Screen
  ↓
Choose Name + Avatar
  ↓
┌────────────────┬────────────────┬────────────────┐
↓                ↓                ↓
Create Room     Join Room       Quick Join
 ↓                ↓                ↓
Room/Game       Room/Game       Running Game
      \           |                /
       \          |               /
               Game Starts
                   ↓
           Drawing/Guessing
                   ↓
                Scoring
                   ↓
             Round Result
                   ↓
               Next Round
```

## 💻 Local Setup

### Clone the Repository

```bash
git clone https://github.com/abhayguptadev/skribbl_clone.git
cd skribbl_clone
```

### Backend Setup

Change into the backend directory:

```bash
cd skribbl_backend/backend
```

Create the virtual environment:

```bash
python -m venv venv
```

Activate the virtual environment on Windows:

```bash
venv\Scripts\activate
```

Install the required packages:

```bash
pip install -r requirements.txt
```

Apply migrations:

```bash
python manage.py migrate
```

Run the development server:

```bash
python manage.py runserver
```

### Frontend Configuration
```bash
flutter doctor
```

* **If the command runs successfully:** You will see a status report of your installation. If everything looks good, proceed straight to
**Step 2**.
* **If you get a "Command not found" or "Not recognized" error:**
  1. Download the latest **Flutter SDK** zip file from the official website.
  2. Extract the zip file and save the folder in a safe directory (e.g., `C:\src\flutter` on Windows or `~/development/flutter` on macOS).
  3. Copy the full path of the `bin` folder inside it (e.g., `C:\src\flutter\bin`).
  4. Add this path to your system's **Environment Variables** (under the `Path` variable).
  5. **Restart your terminal** or IDE, then execute `flutter doctor` again to verify.


Change into the frontend directory:

```bash
cd skribbl
```


Configure the Flutter dependencies:

```bash
flutter pub get
```

Launch the app:

```bash
flutter run -d chrome
```

## 📌 Project Status

**Completed**

The current implementation supports:

* Flutter app deployment
* Django server
* RESTful APIs
* Live WebSocket-based gameplay
* Room creation
* Room entry
* Quick join functionality
* Draw and guess features
* Scoring mechanism
* Rounds
* Player management
* SQLite database storage

## 👨‍💻 Developer

**Abhay Gupta**

Full-Stack App Developer

GitHub:
https://github.com/abhayguptadev

Portfolio:
https://abhayguptadev.com
