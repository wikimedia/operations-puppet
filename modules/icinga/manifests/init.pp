class icinga {

    @monitor_group { 'misc_eqiad': description => 'eqiad misc servers' }
    @monitor_group { 'misc_pmtpa': description => 'pmtpa misc servers' }
    # This needs to be consolited in the virt cluster probably
    @monitor_group { 'labsnfs_eqiad': description => 'eqiad labsnfs server servers' }

    # include all the others...

}
