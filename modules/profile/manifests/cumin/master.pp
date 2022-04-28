# @summary profile to manage cumin masters
# @param puppetdb_host the host running puppetdb
# @param datacenters list of datacenters
# @param kerberos_kadmin_host the host running kerberos kadmin
# @param monitor_agentrun weather to monitor agent runs
# @param email_alerts whether to send email alerts
class profile::cumin::master (
    Stdlib::Host  $puppetdb_host        = lookup('puppetdb_host'),
    Array[String] $datacenters          = lookup('datacenters'),
    Stdlib::Host  $kerberos_kadmin_host = lookup('kerberos_kadmin_server_primary'),
    Boolean       $monitor_agentrun     = lookup('profile::cumin::monitor_agentrun'),
    Boolean       $email_alerts         = lookup('profile::cumin::master::email_alerts'),
) {
    include passwords::phabricator
    $cumin_log_path = '/var/log/cumin'
    $ssh_config_path = '/etc/cumin/ssh_config'
    # Ensure to add FQDN of the current host also the first time the role is applied
    $cumin_masters = (wmflib::role_hosts('cluster::management]') << $facts['networking']['fqdn']).sort.unique
    $mariadb_roles = Profile::Mariadb::Role
    $mariadb_sections = Profile::Mariadb::Valid_section
    $owners = profile::contacts::get_owners().values.flatten.unique

    keyholder::agent { 'cumin_master':
        trusted_groups => ['root'],
    }

    ensure_packages([
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
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template('profile/cumin/config.yaml.erb'),
        require => File['/etc/cumin'],
    }

    file { '/etc/cumin/config-installer.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template('profile/cumin/config-installer.yaml.erb'),
        require => File['/etc/cumin'],
    }

    file { '/etc/cumin/aliases.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/cumin/aliases.yaml.erb'),
        require => File['/etc/cumin'],
    }

    file { '/usr/local/sbin/check-cumin-aliases':
        ensure => file,
        source => 'puppet:///modules/profile/cumin/check_cumin_aliases.py',
        mode   => '0544',
        owner  => 'root',
        group  => 'root',
    }

    file { '/usr/local/bin/secure-cookbook':
        ensure => file,
        source => 'puppet:///modules/profile/cumin/secure_cookbook.py',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { $ssh_config_path:
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0640',
        source => 'puppet:///modules/profile/cumin/ssh_config',
    }

    # Check aliases periodic job, splayed between the week across the Cumin masters
    $times = cron_splay($cumin_masters, 'weekly', 'cumin-check-aliases')

    systemd::timer::job { 'cumin-check-aliases':
        ensure        => 'present',
        user          => 'root',
        description   => 'Checks the cumin aliases file for problems.',
        command       => '/usr/local/sbin/check-cumin-aliases',
        send_mail     => $email_alerts,
        ignore_errors => true,
        interval      => { 'start' => 'OnCalendar', 'interval' => $times['OnCalendar'] },
    }

    class { 'phabricator::bot':
        username => 'ops-monitoring-bot',
        token    => $passwords::phabricator::ops_monitoring_bot_token,
        owner    => 'root',
        group    => 'root',
    }
    if $monitor_agentrun {
        include profile::cumin::monitoring_agentrun
    }
}
