import uuid
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from game.game_manager import game_manager
from game.word_manager import WORD_BANKS
from .serializers import CreateRoomSerializer, JoinRoomSerializer

class CreateRoomView(APIView):
    def post(self, request):
        serializer = CreateRoomSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({"error": "Invalid data", "details": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        player_name = data.pop("playerName")
        host_id = str(uuid.uuid4())[:8]

        room = game_manager.create_room(
            host_id=host_id,
            host_name=player_name,
            settings_dict=data
        )

        return Response({
            "message": "Room created successfully",
            "roomCode": room.code,
            "playerId": host_id,
            "isHost": True,
            "room": room.get_public_state(for_player_id=host_id)
        }, status=status.HTTP_201_CREATED)

class JoinRoomView(APIView):
    def post(self, request):
        serializer = JoinRoomSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({"error": "Invalid data", "details": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

        player_name = serializer.validated_data["playerName"]
        room_code = serializer.validated_data["roomCode"].upper()

        room = game_manager.get_room(room_code)
        if not room:
            return Response({"error": "Room not found"}, status=status.HTTP_404_NOT_FOUND)

        if len(room.players) >= room.settings.max_players:
            return Response({"error": "Room is full"}, status=status.HTTP_400_BAD_REQUEST)

        player_id = str(uuid.uuid4())[:8]
        player = room.add_player(player_id=player_id, name=player_name, is_host=False)
        if not player:
            return Response({"error": "Could not join room"}, status=status.HTTP_400_BAD_REQUEST)

        return Response({
            "message": "Joined room successfully",
            "roomCode": room.code,
            "playerId": player_id,
            "isHost": False,
            "room": room.get_public_state(for_player_id=player_id)
        }, status=status.HTTP_200_OK)

class RoomDetailView(APIView):
    def get(self, request, room_code):
        room = game_manager.get_room(room_code.upper())
        if not room:
            return Response({"error": "Room not found"}, status=status.HTTP_404_NOT_FOUND)

        return Response({
            "room": room.get_public_state()
        }, status=status.HTTP_200_OK)

class WordListView(APIView):
    def get(self, request):
        return Response({
            "categories": list(WORD_BANKS.keys()),
            "sampleWords": {cat: words[:5] for cat, words in WORD_BANKS.items()}
        }, status=status.HTTP_200_OK)

class HealthCheckView(APIView):
    def get(self, request):
        return Response({
            "status": "healthy",
            "activeRooms": len(game_manager.rooms),
            "service": "Skribbl Clone Backend"
        }, status=status.HTTP_200_OK)
class QuickJoinRoomView(APIView):

    def post(self, request):
        player_name = request.data.get("player_name")
        avatar = request.data.get("avatar", "🎨")

        if not player_name:
            return Response(
                {
                    "error": "player_name is required."
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Find an already running game with an empty slot
        room = None

        for active_room in game_manager.rooms.values():
            if active_room.phase in (
                "word_choice",
                "drawing",
                "round_result",
            ):
                if len(active_room.players) < active_room.settings.max_players:
                    room = active_room
                    break

        if room is None:
            return Response(
                {
                    "error": "No running game available."
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        # Create player ID
        player_id = str(uuid.uuid4())[:8]

        # Add player directly to the running game
        player = room.add_player(
            player_id=player_id,
            name=player_name,
            is_host=False,
            avatar=avatar,
        )

        if not player:
            return Response(
                {
                    "error": "Could not join the running game."
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            {
                "message": "Joined running game successfully.",
                "roomCode": room.code,
                "playerId": player_id,
                "isHost": False,
                "room": room.get_public_state(
                    for_player_id=player_id
                ),
            },
            status=status.HTTP_201_CREATED,
        )