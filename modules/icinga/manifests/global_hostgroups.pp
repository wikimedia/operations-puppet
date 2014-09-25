#= Class: icinga::global_hostgroups
# Sets up global monitoring groups, mostly misc clusters
#
class icinga::global_hostgroups {

    @monitor_group { 'misc_eqiad':
        description => 'eqiad misc servers'
    }

    @monitor_group { 'misc_pmtpa':
        description => 'pmtpa misc servers'
    }

    @monitor_group { 'misc_codfw':
        description => 'codfw misc servers'
    }

    @monitor_group { 'misc_esams':
        description => 'esams misc servers' 
    }

    @monitor_group { 'misc_ulsfo':
        description => 'ulsfo misc servers'
    }

    # This needs to be consolited in the virt cluster probably
    @monitor_group { 'labsnfs_eqiad':
        description => 'eqiad labsnfs server servers'
    }
}
