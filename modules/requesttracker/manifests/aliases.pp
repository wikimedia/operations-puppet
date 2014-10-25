class requesttracker::aliases {

    file { '/etc/exim4/aliases/rt.wikimedia.org':
        ensure  => present,
        source  => 'puppet:///modules/requesttracker/mail-aliases',
    }

}

