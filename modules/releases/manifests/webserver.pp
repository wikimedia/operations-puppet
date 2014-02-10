class releases::webserver (
        $sitename = undef,
        $docroot = undef,
        $server_admin = undef,
) {
    file { '/srv/org':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/srv/org/wikimedia':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { "/srv/org/wikimedia/${docroot}":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    include 'webserver::apache'
    @webserver::apache::module { ['rewrite']: }
    @webserver::apache::site { $sitename:
        docroot      => "/srv/org/wikimedia/$docroot/",
        server_admin => $server_admin,
        require      => [
            Webserver::Apache::Module['rewrite'],
            File['/srv/org/wikimedia/releases']
        ],
    }
}
