# SPDX-License-Identifier: BSD-3-Clause
# from django.db import models
# from social_django.models import USER_MODEL, AbstractUserSocialAuth, DjangoStorage
from social_django.models import AbstractUserSocialAuth, DjangoStorage


class CustomUserSocialAuth(AbstractUserSocialAuth):
    pass
#    user = models.ForeignKey(
#        USER_MODEL, related_name="custom_social_auth", on_delete=models.CASCADE
#    )


class CustomDjangoStorage(DjangoStorage):
    user = CustomUserSocialAuth
