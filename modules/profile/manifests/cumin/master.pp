class profile::cumin::master (
    $puppetdb_host  = hiera('profile::cumin::master::puppetdb_host'),
    $datacenters    = hiera('datacenters'),
) {
    include passwords::phabricator
    $cumin_log_path = '/var/log/cumin'

    ::keyholder::agent { 'cumin_master':
        trusted_groups => ['root'],
    }

    require_package([
        'cumin',
        'python-dnspython',
        'python-phabricator',
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
        mode   => '0750',
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
        mode    => '0640',
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

    file { '/usr/local/lib/python2.7/dist-packages/wmf_auto_reimage_lib.py':
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

    class { '::phabricator::bot':
        username => 'ops-monitoring-bot',
        token    => $passwords::phabricator::ops_monitoring_bot_token,
        owner    => 'root',
        group    => 'root',
    }
}
