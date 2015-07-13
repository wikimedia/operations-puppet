class base::labs inherits base {
    include apt::unattendedupgrades,
        apt::noupgrade

    # Labs instances /var is quite small, provide our own default
    # to keep less records (T71604).
    file { '/etc/default/acct':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/labs-acct.default',
    }

    if $::operatingsystem == 'Debian' {
        # Turn on idmapd by default
        file { '/etc/default/nfs-common':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/base/labs/nfs-common.default',
        }
    }
}
