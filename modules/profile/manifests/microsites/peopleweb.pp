# let users publish their own HTML in their home dirs
class profile::microsites::peopleweb (
    Stdlib::Host     $deployment_server = lookup('deployment_server'),
    Stdlib::Host     $sitename          = lookup('profile::microsites::peopleweb::sitename'),
    Stdlib::Unixpath $docroot           = lookup('profile::microsites::peopleweb::docroot'),
    Stdlib::Host     $rsync_src_host    = lookup('profile::microsites::peopleweb::rsync_src_host'),
    Stdlib::Host     $rsync_dst_host    = lookup('profile::microsites::peopleweb::rsync_dst_host'),
){

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

    base::service_auto_restart { 'apache2': }

    wmflib::dir::mkdir_p($docroot)

    file { "${docroot}/index.html":
        content => template('profile/microsites/peopleweb/index.html.erb'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }
    include profile::idp::client::httpd

    monitoring::service { 'https-peopleweb':
        description   => 'HTTPS-peopleweb',
        check_command => "check_https_url!${sitename}!https://${sitename}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/People.wikimedia.org',
    }

    motd::script { 'people-motd':
        ensure  => present,
        content => "#!/bin/sh\necho '\nThis is people.wikimedia.org.\nFiles you put in 'public_html' in your home dir will be accessible on the web.\nMore info on https://wikitech.wikimedia.org/wiki/People.wikimedia.org.\n'",
    }

    backup::set {'home': }

    rsyslog::input::file { 'apache2-error':
        path => '/var/log/apache2/*error*.log',
    }

    # allow copying /home from one server to another for migrations
    ensure_packages(['rsync'])
    rsync::quickdatacopy { 'people-home':
        ensure      => present,
        auto_sync   => false,
        source_host => $rsync_src_host,
        dest_host   => $rsync_dst_host,
        module_path => '/home',
    }
}
