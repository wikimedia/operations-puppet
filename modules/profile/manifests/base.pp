class profile::base(
    $puppetmaster  = hiera('puppetmaster'),
    $dns_alt_names = hiera('profile::base::dns_alt_names', false),
    $use_apt_proxy = hiera('profile::base::use_apt_proxy', true),
    $domain_search = hiera('profile::base::domain_search', $::domain),
    $remote_syslog = hiera('profile::base:remote_syslog', ['syslog.eqiad.wmnet', 'syslog.codfw.wmnet']),
    $monitoring = hiera('profile::base::monitoring', true),
    $core_dump_pattern = hiera('profile::base::core_dump_pattern', '/var/tmp/core/core.%h.%e.%p.%t'),
    $ssh_server_settings = hiera('profile::base::ssh_server_settings', {}),
    $nrpe_allowed_hosts = hiera('profile::base::nrpe_allowed_hosts', '127.0.0.1,208.80.154.14,208.80.153.74,208.80.155.119'),
    $group_contact = hiera('contactgroups', 'admins'),
    $check_disk_options = hiera('profile::base::check_disk_options', '-w 6% -c 3% -l -e -A -i "/srv/sd[a-b][1-3]" --exclude-type=tracefs'),
    $check_disk_critical = hiera('profile::base::check_disk_critical', false),
) {
    require ::profile::base::certificates
    class { '::apt':
        use_proxy => $use_apt_proxy,
    }

    file { ['/usr/local/sbin', '/usr/local/share/bash']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    class { '::base::puppet':
        server        => $puppetmaster,
        dns_alt_names => $dns_alt_names,
    }

    # Temporary workaround for T140100. Remove as soon as Labs instances get
    # grub-pc or trusty gets phased out from Labs, whichever comes first.
    if ($::realm == 'production') or (os_version('debian >= jessie')) {
        class { '::grub::defaults':
        }
    }

    include ::passwords::root

    class { '::base::resolving':
        domain_search => $domain_search,
    }

    class { '::rsyslog': }

    if $remote_syslog {
        class { '::base::remote_syslog':
            enable        => true,
            central_hosts => $remote_syslog,
        }
    }

    #TODO: make base::sysctl a profile itself?
    class { '::base::sysctl': }
    class { '::motd': }
    class { '::base::standard_packages': }
    class { '::base::environment':
        core_dump_pattern => $core_dump_pattern,
    }

    class { '::base::phaste': }
    class { '::base::screenconfig': }

    class { '::ssh::client': }

    # Ssh server default settings are good for most installs, but some overrides
    # might be needed

    create_resources('class', {'ssh::server' => $ssh_server_settings})

    # TODO: Fix the whole top-scope variable override thing
    # we currently have for these two
    include ::role::salt::minions
    include ::trebuchet

    class { '::nrpe':
        allowed_hosts => $nrpe_allowed_hosts,
    }

    class { '::base::kernel': }
    class { '::base::debdeploy': }

    # lint:ignore:quoted_booleans
    if $::is_virtual == 'false' {
        class { '::ipmi::monitor': }
    }
    # lint:endignore

    if os_version('debian >= jessie') {
        class { '::base::initramfs': }
    }

    # unless disabled in Hiera, have Icinga monitoring (T151632)
    if $monitoring {
        class { '::base::monitoring::host':
            contact_group            => $group_contact,
            nrpe_check_disk_options  => $check_disk_options,
            nrpe_check_disk_critical => $check_disk_critical,
        }
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
