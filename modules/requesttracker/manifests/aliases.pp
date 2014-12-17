class requesttracker::aliases {
    file { '/etc/exim4/aliases/rt':
        source => "modules/requesttracker/rt.aliases"
    }
}
