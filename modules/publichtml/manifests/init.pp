# server with user public_html directories enabled and nothing else
# no critical services, in fact no services at all should run here

class publichtml (
    $sitename = undef,
    $docroot = '/srv/org/wikimedia/publichtml',
    $server_admin = undef,
) {

    system::role { 'publichtml':
        description => 'web server of public_html directories'
    }

    apache::site { $sitename:
        content => template('publichtml/apacheconfig.erb')
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
        content => template('publichtml/index.html.erb'),
    }

    include ::apache::mod::userdir
    include ::apache::mod::cgi
    include ::apache::mod::php5

    monitor_service { 'http':
        description   => 'HTTP',
        check_command => "check_http_url!${sitename}!http://${sitename}"
    }

}
