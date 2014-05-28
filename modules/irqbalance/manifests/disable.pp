
class irqbalance::disable {
    service { "irqbalance":
        enable => false,
        ensure => stopped,
    }
}
