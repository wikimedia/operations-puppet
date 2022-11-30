# SPDX-License-Identifier: BSD-3-Clause
import re

from social_core.backends.oauth import OAuthAuth

NAME_RE = re.compile(r"([^O])Auth")

LEGACY_NAMES = ["username", "email"]


def backend_name(backend):
    name = backend.__name__
    name = name.replace("OAuth", " OAuth")
    name = name.replace("OpenId", " OpenId")
    name = name.replace("Sandbox", "")
    name = NAME_RE.sub(r"\1 Auth", name)
    return name


def backend_class(backend):
    return backend.name.replace("-", " ")


def icon_name(name):
    return {
        "stackoverflow": "stack-overflow",
        "google-oauth": "google",
        "google-oauth2": "google",
        "google-openidconnect": "google",
        "yahoo-oauth": "yahoo",
        "facebook-app": "facebook",
        "email": "envelope",
        "vimeo": "vimeo-square",
        "linkedin-oauth2": "linkedin",
        "vk-oauth2": "vk",
        "live": "windows",
        "username": "user",
    }.get(name, name)


def slice_by(value, items):
    return [value[n: n + items] for n in range(0, len(value), items)]


def social_backends(backends):
    return filter_backends(backends, lambda name, backend: name not in LEGACY_NAMES)


def legacy_backends(backends):
    return filter_backends(backends, lambda name, backend: name in LEGACY_NAMES)


def oauth_backends(backends):
    return filter_backends(
        backends, lambda name, backend: issubclass(backend, OAuthAuth)
    )


def filter_backends(backends, filter_func):
    backends = [item for item in backends.items() if filter_func(*item)]
    backends.sort(key=lambda backend: backend[0])
    return backends
