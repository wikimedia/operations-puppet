class generic::wikidev-umask {
    # set umask to 0002 for wikidev users, per RT-804
    file { '/etc/profile.d/umask-wikidev.sh':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/generic/environment/umask-wikidev-profile-d.sh',
    }
}
