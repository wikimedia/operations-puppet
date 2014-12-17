class requesttracker::aliases {
    file { '/etc/exim4/aliases/rt':
        owner   => root,
        group   => root,
        mode    => 0444,
        source  => 'modules/requesttracker/rt.aliases',
    }
}
