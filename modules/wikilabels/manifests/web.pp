# SPDX-License-Identifier: Apache-2.0
# = Class: wiklabels::web
# Sets up a uwsgi based web server for Wikilabels running python3
#
class wikilabels::web (
    $branch = 'master',
) {

    $venv_path = '/srv/wikilabels/venv'
    $config_path = '/srv/wikilabels/config'

    # Let's use a virtualenv for maximum flexibility - we can convert
    # this to deb packages in the future if needed.
    # FIXME: Use debian packages for all the packages needing compilation
    ensure_packages(['virtualenv', 'python3-dev', 'libffi-dev',
        'libpq-dev', 'g++', 'libmemcached-dev', 'nodejs', 'zlib1g-dev', 'postgresql-client'])

    file { '/srv':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    file { '/srv/wikilabels':
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0775',
        recurse => true,
        require => File['/srv'],
    }

    git::clone { 'wikilabels-wikimedia-config':
        ensure    => present,
        origin    => 'https://github.com/wikimedia/wikilabels-wmflabs-deploy.git',
        directory => $config_path,
        branch    => $branch,
        owner     => 'www-data',
        group     => 'www-data',
        require   => File['/srv/wikilabels'],
    }

    uwsgi::app { 'wikilabels-web':
        settings => {
            uwsgi => {
                plugins     => 'python3,router_redirect',
                'wsgi-file' => "${config_path}/labels_web.py",
                master      => true,
                chdir       => $config_path,
                http-socket => '0.0.0.0:8080',
                venv        => $venv_path,
                processes   => $facts['processorcount'] * 4,
                die-on-term => true,
                harakiri    => 30,
                # lint:ignore:single_quote_string_with_variables
                route-if    => 'equal:${HTTP_X_FORWARDED_PROTO};http redirect-permanent:https://${HTTP_HOST}${REQUEST_URI}',
                # lint:endignore
            }
        },
    }

    systemd::timer::job { 'wikilabels-remove_expired_tasks':
        ensure      => present,
        description => 'Remove tasks that a user assigned to themself but did not finish for long time.',
        command     => '/srv/wikilabels/venv/bin/python /srv/wikilabels/config/submodules/wikilabels/utility remove_expired_tasks --config=/srv/wikilabels/config/config/',
        user        => 'www-data',
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 00:00:00'},
    }

}
