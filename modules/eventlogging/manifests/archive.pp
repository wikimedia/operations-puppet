# == Class: eventlogging::archive
#
# This class creates log directories for EventLogging logs under the
# /var/log hierarchy and provisions an Rsync server module that serves
# log data to backup destinations.
#
class eventlogging::archive {
    include rsync::server

    file { [ '/var/log/eventlogging', '/var/log/eventlogging/archive' ]:
        ensure  => directory,
        owner   => 'eventlogging',
        group   => 'eventlogging',
        mode    => '0664',
    }

    rsync::server::module { 'eventlogging':
        path        => '/var/log/eventlogging',
        read_only   => 'yes',
        list        => 'yes',
        require     => File['/var/log/eventlogging'],
        hosts_allow => $::network::constants::all_networks,
    }

    file { '/etc/logrotate.d/eventlogging':
        source  => 'puppet:///modules/eventlogging/logrotate',
        require => File['/var/log/eventlogging/archive'],
        mode    => '0444',
    }
}
