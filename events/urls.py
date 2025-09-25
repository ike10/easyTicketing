from django.urls import path
from . import views

urlpatterns = [
    path('', views.event_list, name='event_list'),
    path('event/<slug:slug>/', views.event_detail, name='event_detail'),
    path('event/<slug:slug>/book/', views.book_ticket, name='book_ticket'),
    path('accounts/signup/', views.signup, name='signup'),
]
