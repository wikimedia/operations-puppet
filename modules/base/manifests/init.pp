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

    include passwords::root
    include base::grub
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

    # include base::monitor::host.
    # if contactgroups is set, then use it
    # as the monitor host's contact group.

    $group_contact = hiera('contactgroups', 'admins')

    class { 'base::monitoring::host':
        contact_group => $group_contact,
    }
}
