from django.urls import path

from . import views


urlpatterns = [
    path("signup/", views.signup, name="signup"),
    path("edit_profile/", views.UserEditView.as_view(), name="edit-profile"),
]