# = Class: role::beta::availability_collector
# collect availability metrics for the beta / staging clusters
class role::beta::availability_collector {
    diamond::collector { 'VarnishStatus':
        source   => 'puppet:///modules/diamond/collector/varnishstatus.py',
        settings => {
            path_prefix => $::labsproject,
            path        => 'availability',
        }
    }
}

