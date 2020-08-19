class profile::cumin::master (
    $puppetdb_host  = hiera('puppetdb_host'),
    $datacenters    = hiera('datacenters'),
) {
    include passwords::phabricator
    $cumin_log_path = '/var/log/cumin'
    $ssh_config_path = '/etc/cumin/ssh_config'
    # Ensure to add FQDN of the current host also the first time the role is applied
    $cumin_masters = unique(concat(query_nodes('Class[Role::Cumin::Master]'), [$::fqdn]))
    $mariadb_roles = Profile::Mariadb::Role
    $mariadb_sections = Profile::Mariadb::Valid_section

    ::keyholder::agent { 'cumin_master':
        trusted_groups => ['root'],
    }

    require_package([
        'clustershell',  # Installs nodeset CLI that is useful to mangle host lists.
        'cumin',
        'python3-dnspython',
        'python3-phabricator',
        'python3-requests',
    ])

    file { $cumin_log_path:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    file { '/etc/cumin':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/cumin/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template('profile/cumin/config.yaml.erb'),
        require => File['/etc/cumin'],
    }

    file { '/etc/cumin/config-installer.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template('profile/cumin/config-installer.yaml.erb'),
        require => File['/etc/cumin'],
    }

    file { '/etc/cumin/aliases.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/cumin/aliases.yaml.erb'),
        require => File['/etc/cumin'],
    }

    # Auto reimage script
    # Temporarily in Puppet, once the spinoff from Switchdc will be in production
    # This will just become an available task in it

    file { '/var/log/wmf-auto-reimage':
        ensure => directory,
        mode   => '0750',
        owner  => 'root',
        group  => 'root',
    }

    if os_version('debian == stretch') {
        $python_version = '3.5'
    } elsif os_version('debian == buster') {
        $python_version = '3.7'

        apt::package_from_component { 'spicerack':
            component => 'component/spicerack',
            packages  => ['python3-tqdm'],
            priority  => 1002,
        }
    }

    file { "/usr/local/lib/python${python_version}/dist-packages/wmf_auto_reimage_lib.py":
        ensure => present,
        source => 'puppet:///modules/profile/cumin/wmf_auto_reimage_lib.py',
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }

    file { '/usr/local/sbin/wmf-auto-reimage':
        ensure => present,
        source => 'puppet:///modules/profile/cumin/wmf_auto_reimage.py',
        mode   => '0544',
        owner  => 'root',
        group  => 'root',
    }

    file { '/usr/local/sbin/wmf-auto-reimage-host':
        ensure => present,
        source => 'puppet:///modules/profile/cumin/wmf_auto_reimage_host.py',
        mode   => '0544',
        owner  => 'root',
        group  => 'root',
    }

    file { '/usr/local/sbin/check-cumin-aliases':
        ensure => present,
        source => 'puppet:///modules/profile/cumin/check_cumin_aliases.py',
        mode   => '0544',
        owner  => 'root',
        group  => 'root',
    }

    file { '/usr/local/bin/secure-cookbook':
        ensure => present,
        source => 'puppet:///modules/profile/cumin/secure_cookbook.py',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { $ssh_config_path:
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0640',
        source => 'puppet:///modules/profile/cumin/ssh_config',
    }

    # Check aliases cron, splayed between the week across the Cumin masters
    $times = cron_splay($cumin_masters, 'weekly', 'cumin-check-aliases')
    cron { 'cumin-check-aliases':
        command => '/usr/local/sbin/check-cumin-aliases',
        user    => 'root',
        weekday => $times['weekday'],
        hour    => $times['hour'],
        minute  => $times['minute'],
    }

    class { '::phabricator::bot':
        username => 'ops-monitoring-bot',
        token    => $passwords::phabricator::ops_monitoring_bot_token,
        owner    => 'root',
        group    => 'root',
    }
}
