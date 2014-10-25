class requesttracker::aliases {

    file { '/etc/aliases':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/requesttracker/mail-aliases',
    }

}

