class base::apt_sources {
    # thirdparty/hwraid contains hardware-specific RAID/monitoring tools
    # They are only used on baremetal servers
    if $facts['is_virtual'] == false and os_version('debian >= stretch') {
        apt::repository { 'wikimedia-hwraid':
            uri         => 'http://apt.wikimedia.org/wikimedia',
            dist        => "${::lsbdistcodename}-wikimedia",
            components  => 'thirdparty/hwraid',
        }
    }
}
