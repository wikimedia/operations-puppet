class base {
    include apt

    file { '/usr/local/sbin':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $puppetmaster = hiera('puppetmaster')

    class { 'base::puppet':
        server   => $puppetmaster,
    }

    # Temporary workaround for T140100. Remove as soon as Labs instances get
    # grub-pc or trusty gets phased out from Labs, whichever comes first.
    if ($::realm == 'production') or (os_version('debian >= jessie')) {
        include grub::defaults
    }

    include passwords::root
    include base::resolving
    include ::rsyslog
    include base::remote_syslog
    include base::sysctl
    include ::motd
    include base::standard_packages
    include base::environment
    include base::phaste
    include base::screenconfig
    include base::certificates
    include ssh::client
    include ssh::server
    include role::salt::minions
    include ::trebuchet
    include nrpe
    include base::kernel
    include base::debdeploy

    include ipmi::monitor

    if os_version('debian >= jessie') {
        include base::initramfs
    }

    # include base::monitor::host.
    # if contactgroups is set, then use it
    # as the monitor host's contact group.

    $group_contact = hiera('contactgroups', 'admins')

    class { 'base::monitoring::host':
        contact_group => $group_contact,
    }

    if os_version('ubuntu == trusty') {
        file { '/etc/logrotate.d/upstart':
            mode   => '0444',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/base/logrotate/upstart',
        }
    }
}
