# = Class: role::labs::extdist
#
# This class sets up a tarball generator for the Extension Distributor
# extension enabled on mediawiki.org.
#
class role::labs::extdist {

    include role::labs::lvm::srv

    user { 'extdist':
        ensure => present,
        system => true,
    }

    file { '/srv/src':
        ensure  => directory,
        owner   => 'extdist',
        group   => 'www-data',
        mode    => '0755',
        require => Mount['/srv']
    }

    file { '/srv/extdist':
        ensure  => directory,
        owner   => 'extdist',
        group   => 'www-data',
        mode    => '0755',
        require => Mount['/srv']
    }

    git::clone {'labs/tools/extdist':
        directory => '/srv/extdist',
        ensure    => latest,
        branch    => 'master',
        require   => [File['/srv/extdist'], User['extdist']],
        owner     => 'extdist',
        group     => 'extdist',
    }

    package{'python-flask':
        ensure => latest,
    }

    uwsgi::app { 'extdist':
        require              => [Git::Clone['labs/tools/extdist'], Package['python-flask']],
        settings             => {
            uwsgi            => {
                'socket'     => '/run/uwsgi/extdist.sock',
                'wsgi-file'  => '/srv/extdist/extdist.wsgi',
                'master'     => true,
                'processes' => 4,
                'chdir'      => '/srv/extdist',
            },
        },
    }

    cron { 'extdist-generate-tarballs':
        command => '/usr/bin/python /srv/extdist/nightly.py',
        user    => 'extdist',
        hour    => '0',
        require => [Git::Clone['labs/tools/extdist'], User['extdist']]
    }

    nginx::site { 'extdist':
        require => Uwsgi::App['extdist'],
        content => template('extdist.nginx.erb'),
    }
}
