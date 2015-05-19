# Class: raid
#
# checks and changes the raid configuration of a nodes
# its main purpose is to avoid performance issues by
# disabling the cycle of "auto learn"

class raid {

    $auto_learn_mode = 1 # disable by default

    package { 'megacli':
        ensure => installed, # done by the installer
    }

    file { '/usr/local/bin/setup_raid_bbu.sh':
        ensure => present,
        mode   => '0744',
        owner  => root,
        group  => root,
        source => 'puppet:///modules/raid/setup_raid_bbu.sh',
    }

    file { '/etc/BbuProperties':
        ensure  => present,
        mode    => '0644',
        owner   => root,
        group   => root,
        content => template('raid/BbuProperties.erb'),
    }

    exec { 'setup_raid_bbu.sh':
        command  => 'setup_raid_bbu.sh',
        path     => '/bin:/usr/bin:/usr/sbin:/usr/local/bin',
        require  => [ File['/usr/local/bin/setup_raid_bbu.sh'],
                    File['/etc/BbuProperties'], Package['megacli'] ],
        unless   => '/usr/local/bin/setup_raid_bbu.sh -c'
    }
}
