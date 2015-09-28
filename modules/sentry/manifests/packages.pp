# == Class: sentry::packages
#
# Contains Sentry dependencies which have a package on Debian Jessie.
#
class sentry::packages {

    # System packages compatible with Sentry 7.7.0 on Debian Jessie,
    # as of 2015-07-30. The rest of the Python packages are packaged
    # as a virtualenv inside operations/software/sentry.

    package { [
        'python-beautifulsoup',
        'python-celery',
        'python-cssutils',
        'python-dateutil',
        'python-django-crispy-forms',
        'python-django-jsonfield',
        'python-django-picklefield',
        'python-ipaddr',
        'python-mock',
        'python-progressbar',
        'python-psycopg2',
        'python-pytest',
        'python-redis',
        'python-setproctitle',
        'python-six',
    ]:
        ensure => present,
    }
}
