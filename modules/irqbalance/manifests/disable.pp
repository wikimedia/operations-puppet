
class irqbalance::disable {
    service { 'irqbalance':
        ensure => stopped,
        enable => false,
    }

    # Apparently puppet can't actually disable this upstart service,
    #  but this is a decent workaround
    file { '/etc/default/irqbalance':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/irqbalance/irqbalance.disabled.default',
    }
}
