# == Class: sentry::packages
#
# Contains Sentry dependencies which have a package on Debian Jessie.
#
class sentry::packages {
    # System packages compatible with Sentry 7.7.0 on Debian Jessie
    # as of 2015-07-30. The rest of the python packages are packaged
    # as a virtualenv inside `operations/software/sentry`.

    require_package('python-beautifulsoup')
    require_package('python-celery')
    require_package('python-cssutils')
    require_package('python-dateutil')
    require_package('python-django-crispy-forms')
    require_package('python-django-jsonfield')
    require_package('python-django-picklefield')
    require_package('python-ipaddr')
    require_package('python-mock')
    require_package('python-progressbar')
    require_package('python-psycopg2')
    require_package('python-pytest')
    require_package('python-redis')
    require_package('python-setproctitle')
    require_package('python-six')
}

