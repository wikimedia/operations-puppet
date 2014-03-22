# toollabs::toolwatcher sets up a host with a service that scans every
# two minutes for tool accounts whose home directory doesn't exist
# yet.  For each such tool account, the toolwatcher creates the home
# directory with the subdirectories cgi-bin and public_html owned by
# the tool account and its group and sets the permissions to
# g+srwx,o+rx.
class toollabs::toolwatcher
inherits toollabs {
    package { 'misctools':
        ensure => latest,
    }

    file { '/etc/init/toolwatcher.conf':
        ensure => file,
        source => 'puppet:///modules/toollabs/toolwatcher.conf',
        user   => 'root',
        group  => 'root',
        mode   => '0444',
    }

    service { 'toolwatcher':
        ensure    => running,
        provider  => 'upstart',
        require   => File['/etc/init/toolwatcher.conf'],
        subscribe => File['/etc/init/toolwatcher.conf'],
    }
}
