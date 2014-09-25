# -*- coding: utf-8 -*-
"""
  Django CORS middleware for graphite-web

  If the Origin header on the request matches one of the patterns in the
  CORS_ORIGINS settings, set appropriate CORS headers.

"""
import re

from django.conf import settings


class CorsMiddleware(object):
    """Django middleware for adding CORS headers to responses."""
    def process_response(self, request, response):
        origin = request.META.get('HTTP_ORIGIN', '')
        if any(re.match(regexp, origin) for regexp in settings.CORS_ORIGINS):
            response['Access-Control-Allow-Origin'] = origin
            response['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
            response['Access-Control-Allow-Headers'] = (
                'origin, authorization, accept')
            response['Access-Control-Allow-Credentials'] = 'true'
        return response
