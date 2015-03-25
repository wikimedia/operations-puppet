# == Class: sentry
#
# Sentry is a realtime, platform-agnostic error logging and aggregation platform.
#
class sentry {
    package { 'sentry/sentry':
        provider => 'trebuchet',
    }

    require_package('postgresql')

    # System packages compatible with Sentry 7.4.3 on Debian Jessie on 2015-03-31
    require_package('python-beautifulsoup')
    require_package('python-cssutils')
    require_package('python-django-crispy-forms')
    require_package('python-django-jsonfield')
    require_package('python-django-picklefield')
    require_package('python-ipaddr')
    require_package('python-mock')
    require_package('python-progressbar')
    require_package('python-pytest')
    require_package('python-redis')
    require_package('python-six')
    require_package('python-setproctitle')

    require_package('python-psycopg2')
}
