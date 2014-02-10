class releases::webserver {

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
    file { '/srv/org/wikimedia/releases':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    include 'webserver::apache'
    @webserver::apache::module { ['rewrite']: }
    @webserver::apache::site { 'releases.wikimedia.org':
        docroot      => '/srv/org/wikimedia/releases/',
        server_admin => 'noc@wikimedia.org',
        require      => [
            Webserver::Apache::Module['rewrite'],
            File['/srv/org/wikimedia/releases']
        ],
    }
}
