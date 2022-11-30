# SPDX-License-Identifier: BSD-3-Clause
from functools import wraps

from common.utils import common_context
from django.conf import settings
from django.shortcuts import render
from social_django.utils import load_strategy


def render_to(template):
    """Simple render_to decorator"""

    def decorator(func):
        """Decorator"""

        @wraps(func)
        def wrapper(request, *args, **kwargs):
            """Rendering method"""
            out = func(request, *args, **kwargs) or {}
            if isinstance(out, dict):
                out = render(
                    request,
                    template,
                    common_context(
                        settings.AUTHENTICATION_BACKENDS,
                        load_strategy(),
                        request.user,
                        plus_id=getattr(settings, "SOCIAL_AUTH_GOOGLE_PLUS_KEY", None),
                        **out
                    ),
                )
            return out

        return wrapper

    return decorator
