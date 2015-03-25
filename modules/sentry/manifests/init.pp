# == Class: sentry
#
# Sentry is a realtime, platform-agnostic error logging and aggregation platform.
#
class sentry {
    package { 'sentry/sentry':
        provider => 'trebuchet',
    }

    # Postgresql data store
    require_package(['postgresql', 'python-psycopg2'])

    # System packages compatible with Sentry 7.4.3 on Debian Jessie on 2015-03-31
    require_package(['python-beautifulsoup', 'python-cssutils', 'python-django-crispy-forms',
        'python-django-jsonfield', 'python-django-picklefield', 'python-ipaddr', 'python-mock',
        'python-progressbar', 'python-pytest', 'python-redis', 'python-six', 'python-setproctitle'])
}
