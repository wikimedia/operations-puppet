
class irqbalance::disable {
    service { "irqbalance":
        enable => false,
        ensure => stopped,
    }

    # Apparently puppet can't actually disable this upstart service,
    #  but this is a decent workaround
    file { "/etc/default/irqbalance":
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/irqbalance/irqbalance.disabled.default',
    }
}
