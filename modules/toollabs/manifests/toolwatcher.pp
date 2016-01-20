# toollabs::toolwatcher sets up a host with a service that scans every
# two minutes for tool accounts whose home directory doesn't exist
# yet.  For each such tool account, the toolwatcher creates the home
# directory with the subdirectory public_html owned by the tool
# account and its group and sets the permissions to g+srwx,o+rx.
class toollabs::toolwatcher(
    $active,
) inherits toollabs {
    file { '/usr/local/sbin/toolwatcher':
        source => 'puppet:///modules/toollabs/toolwatcher',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        }

    file { '/etc/init/toolwatcher.conf':
        ensure  => file,
        source  => 'puppet:///modules/toollabs/toolwatcher.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/usr/local/sbin/toolwatcher'],
    }

    service { 'toolwatcher':
        ensure    => ensure_service($active),
        provider  => 'upstart',
        subscribe => File['/etc/init/toolwatcher.conf'],
    }
}
