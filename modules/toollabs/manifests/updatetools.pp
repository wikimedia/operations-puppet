# Set up a service to update the tools and users tables.
class toollabs::updatetools(
    $active
) {
    require_package('python-mysqldb')

    file { '/usr/local/bin/updatetools':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/updatetools',
    }

    file { '/etc/init/updatetools.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('toollabs/updatetools.conf.erb'),
    }

    service { 'updatetools':
        ensure    => ensure_service($active),
        enable    => true,
        subscribe => [File['/etc/init/updatetools.conf'],
                      File['/usr/local/bin/updatetools']],
    }
}
