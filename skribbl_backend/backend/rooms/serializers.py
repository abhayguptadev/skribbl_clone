from rest_framework import serializers

class CreateRoomSerializer(serializers.Serializer):
    playerName = serializers.CharField(max_length=30, required=True)
    maxPlayers = serializers.IntegerField(default=8, min_value=2, max_value=20)
    rounds = serializers.IntegerField(default=3, min_value=2, max_value=10)
    drawTime = serializers.IntegerField(default=60, min_value=15, max_value=240)
    wordChoices = serializers.IntegerField(default=3, min_value=1, max_value=5)
    hintsEnabled = serializers.BooleanField(default=True)
    isPrivate = serializers.BooleanField(default=False)
    customWords = serializers.ListField(
        child=serializers.CharField(max_length=50),
        required=False,
        default=list
    )
    category = serializers.CharField(default="all", required=False)

class JoinRoomSerializer(serializers.Serializer):
    playerName = serializers.CharField(max_length=30, required=True)
    roomCode = serializers.CharField(max_length=10, required=True)
