# server with user public_html directories enabled and nothing else
# no critical services, in fact no services at all should run here

class publichtml (
    $sitename = undef,
    $docroot = '/srv/org/wikimedia/publichtml',
    $server_admin = undef,
) {
    include ::apache

    system::role { 'publichtml':
        description => 'web server of public_html directories'
    }

    file { "/etc/apache2/sites-enabled/${sitename}":
        ensure  => 'present',
        require => [Class['::apache::mod::userdir', '::apache::mod::cgi'],
                    Package[libapache2-mod-php5]],
        path    => "/etc/apache2/sites-enabled/${sitename}",
        mode    => '0444',
        owner   => root,
        group   => root,
        content => template('publichtml/apacheconfig.erb'),
    }

    file { '/etc/apache2/sites-enabled/default':
        ensure  => 'absent',
        path    => '/etc/apache2/sites-enabled/default',
    }

    file { '/srv/org':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/srv/org/wikimedia':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { $docroot:
        ensure  => 'directory',
        path    => $docroot,
        mode    => '0755',
        owner   => root,
        group   => root,
    }

    file { "${docroot}/index.html":
        ensure  => 'present',
        path    => "${docroot}/index.html",
        mode    => '0444',
        owner   => root,
        group   => root,
        content => template('publichtml/index_html.erb'),
    }

    include ::apache::mod::userdir

    monitor_service { 'http':
        description   => 'HTTP',
        check_command => "check_http_url!${sitename}!http://${sitename}"
    }

}
