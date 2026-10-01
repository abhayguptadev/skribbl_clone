from django.urls import re_path
from .consumers import GameConsumer

websocket_urlpatterns = [
    re_path(r'^ws/room/(?P<room_code>[a-zA-Z0-9_-]+)/?$', GameConsumer.as_asgi()),
    re_path(r'^ws/?$', GameConsumer.as_asgi()),
]
