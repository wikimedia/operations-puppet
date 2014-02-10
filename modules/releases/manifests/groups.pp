class releases::groups {
    group { 'mwupld':
            ensure => 'present',
    }
    group { 'mobileupld':
            ensure => 'present',
    }
}
