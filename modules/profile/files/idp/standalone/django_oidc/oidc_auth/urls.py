# SPDX-License-Identifier: BSD-3-Clause
from app import views as app_views
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("", app_views.home),
    path("admin/", admin.site.urls),
    path("email-sent/", app_views.validation_sent),
    path("login/", app_views.home),
    path("logout/", app_views.logout),
    path("done/", app_views.done, name="done"),
    path("ajax-auth/<backend>/", app_views.ajax_auth, name="ajax-auth"),
    path("email/", app_views.require_email, name="require_email"),
    path("country/", app_views.require_country, name="require_country"),
    path("city/", app_views.require_city, name="require_city"),
    path("debug/", app_views.debug),
    path("", include("social_django.urls")),
]
