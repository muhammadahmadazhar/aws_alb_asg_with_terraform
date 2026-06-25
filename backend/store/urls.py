from django.urls import path
from . import views
from .views import DocumentUploadAPIView

urlpatterns = [
    path('', views.product_list, name='product_list'),
    path("api/health/", views.health_check),
    path("upload/", DocumentUploadAPIView.as_view(), name="file-upload"),
]