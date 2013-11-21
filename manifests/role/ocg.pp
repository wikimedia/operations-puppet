# vim: set ts=4 et sw=4:
# role/ocg.pp
# offline content generator

# Virtual resources for the monitoring server
@monitor_group { "ocg_eqiad": description => "offline content generator eqiad" }

class role::ocg {
    system::role { "ocg": description => "offline content generator base" }
    
    deployment::target { 'ocg': }

    package {
        [ 'nodejs' ]:
            ensure => latest;
    }

    file { '/etc/ocg':
        ensure  => link,
        target  => '/srv/deployment/ocg/config/'
    }
}

class role::ocg::test {
    system::role { "ocg-test": description => "offline content generator testing" }

    package {
        [ 'redis-server' ]:
            ensure => latest;
    }
}

class role::ocg::collection {
    system::role { "ocg-collection": description => "offline concent generator for Collection extension" }
    
    deployment::target { 'ocg-collection': }
    
    package { [
        'texlive-xetex',
        'imagemagick',
        ]: ensure => latest;
    }
    
    file { '/var/lib/ocg':
        ensure => directory,
        owner  => ocg,
        group  => wikidev,
        mode   => '2775',
    }
    
    file { '/var/lib/ocg/collection':
        ensure => link,
        target => '/srv/deployment/ocg/collection',
    }

    file { '/etc/init/ocg-collection':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0555',
        source => 'puppet:///files/misc/ocg-collection.conf',
    }
    
    generic::systemuser { 'ocg':
        name          => 'ocg',
        default_group => 'ocg',
        home          => '/var/lib/ocg',
    }

    service { 'ocg-collection':
        ensure     => running,
        hasstatus  => false,
        hasrestart => false,
        enable     => true,
        require    => File['/etc/init/ocg-collection.conf'],
    }

    monitor_service { 'ocg-collection':
        description   => 'Offline Content Generation - Collection',
        check_command => 'check_http_on_port!17080',
    }
}
