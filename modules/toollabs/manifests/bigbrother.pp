# Set up a bigbrother service.
class toollabs::bigbrother($active) {

    # bigbrother needs this perl package
    require_package('libxml-simple-perl')

    file { '/usr/local/sbin/bigbrother':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/bigbrother',
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
