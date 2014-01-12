# gridengine/init.pp
#
# The gridmaster parameter is used in the template to preseed the package
# installation with the (annoyingly) semi-hardcoded FQDN to the grid
# master server.

class gridengine($gridmaster) {
    file { '/var/local/preseed':
        ensure => directory,
        mode   => '0600',
    }

    file { '/var/local/preseed/gridengine.preseed':
        ensure  => 'file',
        require => File['/var/local/preseed'],
        mode    => '0600',
        backup  => false,
        content => template('gridengine/gridengine.preseed.erb'),
    }

    package { 'gridengine-common':
        ensure       => latest,
        require      => File['/var/local/preseed/gridengine.preseed'],
        responsefile => '/var/local/preseed/gridengine.preseed',
    }
}

