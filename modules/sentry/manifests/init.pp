# == Class: sentry
#
# Sentry is a realtime, platform-agnostic error logging and aggregation platform.
#
class sentry {
    package { 'sentry/sentry':
        provider => 'trebuchet',
    }

    require_package('postgresql')

    # pip
    require_package('python-pip')
    # Needed by python-setproctitle (Sentry dependency)
    require_package('python-dev')
    # Needed by python-lxml (Sentry dependency)
    require_package('libxml2-dev')
    require_package('libxslt1-dev')
    # Needed by python-cffi (Sentry dependency)
    require_package('libffi-dev')
    # Needed by python-psycopg2 (Sentry dependency)
    require_package('libpq-dev')

    package { 'python-setuptools':
        ensure => present,
    }

    exec { 'pip_install_sentry':
        command => '/usr/local/bin/pip install .',
        cwd => '/srv/deployment/sentry/sentry',
    }

    # Sadly this has to be done manually and will need to be maintained with sentry updates...
    # I couldn't find a way to make either easy_install or pip process "extra_requires" while
    # pointing to a local source folder
    exec { 'pip_install_psycopg2':
        command => '/usr/local/bin/pip install "psycopg2>=2.5.0,<2.6.0"',
    }
}
