from django.urls import path
from .views import CreateRoomView, JoinRoomView, RoomDetailView, WordListView, HealthCheckView

urlpatterns = [
    path('rooms/', CreateRoomView.as_view(), name='create-room'),
    path('rooms/join/', JoinRoomView.as_view(), name='join-room'),
    path('rooms/<str:room_code>/', RoomDetailView.as_view(), name='room-detail'),
    path('words/', WordListView.as_view(), name='word-list'),
    path('health/', HealthCheckView.as_view(), name='health-check'),
]
