# Set up a bigbrother service.
class toollabs::bigbrother($active) {
    file { '/usr/local/sbin/bigbrother':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        # File is named with .py suffix so that tox will run tests on it
        source => 'puppet:///modules/toollabs/bigbrother.py',
    }

    file { '/etc/init/bigbrother.conf':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/toollabs/bigbrother.conf',
    }

    service { 'bigbrother':
        ensure    => ensure_service($active),
        subscribe => File['/usr/local/sbin/bigbrother', '/etc/init/bigbrother.conf'],
    }
}
