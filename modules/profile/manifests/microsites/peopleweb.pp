# let users publish their own HTML in their home dirs
class profile::microsites::peopleweb (
    $deployment_server = hiera('deployment_server'),
){

    include ::profile::waf::apache2::administrative

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

    class { '::httpd':
        modules => ['userdir', 'rewrite', 'headers'],
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
