# let users publish their own HTML in their home dirs
class profile::microsites::peopleweb (
    $deployment_server = hiera('deployment_server'),
){

    include ::profile::waf::apache2::global_banned_addresses

    ferm::service { 'people-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }

    ferm::service { 'people-http-deployment':
        proto  => 'tcp',
        port   => '80',
        srange => "(@resolve((${deployment_server})) @resolve((${deployment_server}), AAAA))"
    }

    if os_version('debian == jessie') {
        $php_version = '5'
    } else {
        $php_version = '7.0'
    }

    require_package("libapache2-mod-php${php_version}")

    class { '::httpd':
        modules => ['userdir', 'cgi', "php${php_version}", 'rewrite', 'headers'],
    }

    class { '::httpd::mpm':
        mpm => 'prefork'
    }

    class { '::publichtml':
        sitename     => 'people.wikimedia.org',
        server_admin => 'noc@wikimedia.org',
    }

    motd::script { 'people-motd':
        ensure  => present,
        content => "#!/bin/sh\necho '\nThis is people.wikimedia.org.\nFiles you put in 'public_html' in your home dir will be accessible on the web.\nMore info on https://wikitech.wikimedia.org/wiki/People.wikimedia.org.\n'",
    }

    backup::set {'home': }

    rsyslog::input::file { 'apache2-error':
        path => '/var/log/apache2/*error*.log',
    }

}

