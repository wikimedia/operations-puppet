class requesttracker::aliases {

    file { '/etc/aliases':
        ensure  => present,
        source  => 'puppet:///modules/requesttracker/mail-aliases',
    }

}

