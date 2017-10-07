# == Class: hhvm::monitoring
#
# Provisions Diamond collector for HHVM.
#
class hhvm::monitoring {
    include ::standard

    ## Memory statistics

    diamond::collector { 'HhvmApc':
        source  => 'puppet:///modules/hhvm/monitoring/hhvm_apc.py',
    }
}
