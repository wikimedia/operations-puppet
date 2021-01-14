class profile::swift::performance {

    $iface_primary = $facts['interface_primary']

    # RPS/RSS to spread network i/o evenly (for 10Gbps primary interface only)
    if $facts['net_driver'][$iface_primary]['driver'] in ['bnxt_en', 'bnx2x'] {
        interface::rps { 'primary':
            interface => $iface_primary,
        }
    }

}
