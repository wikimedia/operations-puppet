# server with user public_html directories enabled and nothing else
# no critical services, in fact no services at all should run here
class publichtml(
    $sitename     = undef,
    $docroot      = '/srv/org/wikimedia/publichtml',
    $server_admin = undef,
) {
    include ::apache::mod::userdir
    include ::apache::mod::cgi
    include ::apache::mod::php5
    include ::apache::mod::rewrite

    system::role { 'publichtml':
        description => 'web server of public_html directories',
    }

    apache::site { $sitename:
        content => template('publichtml/apacheconfig.erb'),
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
        ensure => 'directory',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { "${docroot}/index.html":
        content => template('publichtml/index.html.erb'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }

    monitoring::service { 'http-peopleweb':
        description   => 'HTTP-peopleweb',
        check_command => "check_http_url!${sitename}!http://${sitename}",
    }
}
