class requesttracker::aliases {
    file { '/etc/exim4/aliases/rt':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/requesttracker/rt.aliases',
    }
}
