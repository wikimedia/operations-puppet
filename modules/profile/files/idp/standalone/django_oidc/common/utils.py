# SPDX-License-Identifier: BSD-3-Clause
from social_core.backends.google import GooglePlusAuth
from social_core.backends.utils import load_backends


def is_authenticated(user):
    if callable(user.is_authenticated):
        return user.is_authenticated()
    else:
        return user.is_authenticated


def associations(user, strategy):
    user_associations = strategy.storage.user.get_social_auth_for_user(user)
    if hasattr(user_associations, "all"):
        user_associations = user_associations.all()
    return list(user_associations)


def common_context(authentication_backends, strategy, user=None, plus_id=None, **extra):
    """Common view context"""
    context = {
        "user": user,
        "available_backends": load_backends(authentication_backends),
        "associated": {},
    }

    if user and is_authenticated(user):
        context["associated"] = {
            association.provider: association
            for association in associations(user, strategy)
        }

    if plus_id:
        context["plus_id"] = plus_id
        context["plus_scope"] = " ".join(GooglePlusAuth.DEFAULT_SCOPE)

    return dict(context, **extra)


def url_for(name, **kwargs):
    if name == "social:begin":
        url = "/login/{backend}/"
    elif name == "social:complete":
        url = "/complete/{backend}/"
    elif name == "social:disconnect":
        url = "/disconnect/{backend}/"
    elif name == "social:disconnect_individual":
        url = "/disconnect/{backend}/{association_id}/"
    else:
        url = name
    return url.format(**kwargs)
