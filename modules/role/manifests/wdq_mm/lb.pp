# == Class: role::wdq_mm::lb
# Load balancer for balancing across multiple instances
# of role::labs::wdq_mm
#
# filtertags: labs-project-wdq-mm
class role::wdq_mm::lb {
    requires_realm('labs')

    class { '::wdq_mm::lb':
    }
}
