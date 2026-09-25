# SPDX-License-Identifier: Apache-2.0
# @summary profile to manage cumin masters
# @param datacenters list of datacenters
# @param kerberos_kadmin_host the host running kerberos kadmin
# @param monitor_agentrun weather to monitor agent runs
# @param puppetdb_micro_host the host running puppetdb-api micro service
# @param puppetdb_micro_port the port running puppetdb-api micro service
# @param email_alerts whether to send email alerts
# @param insetup_role_report_day The day of the month to run the insetup role report
# @param cumin_connect_timeout the timeout value for cumin
# @param insetup_role_report_config the owners and roles mapping for the insetup role report
class profile::cumin::master (
    Array[String]                                     $datacenters                = lookup('datacenters'),
    Stdlib::Host                                      $kerberos_kadmin_host       = lookup('kerberos_kadmin_server_primary'),
    Boolean                                           $monitor_agentrun           = lookup('profile::cumin::monitor_agentrun'),
    Stdlib::Host                                      $puppetdb_micro_host        = lookup('profile::cumin::master::puppetdb_micro_host'),
    Stdlib::Port                                      $puppetdb_micro_port        = lookup('profile::cumin::master::puppetdb_micro_port'),
    Boolean                                           $email_alerts               = lookup('profile::cumin::master::email_alerts'),
    Integer[0,31]                                     $insetup_role_report_day    = lookup('profile::cumin::master::insetup_role_report_day'),
    Integer                                           $cumin_connect_timeout      = lookup('profile::cumin::master::connect_timeout', {'default_value' => 10}),
    Optional[Profile::Cumin::InsetupRoleReportConfig] $insetup_role_report_config = lookup('profile::cumin::master::insetup_role_report_config', {'default_value' => undef}),
) {
    include passwords::phabricator
    $with_openstack = false  # Used in the cumin/config.yaml.erb template
    $cumin_log_path = '/var/log/cumin'
    $ssh_config_path = '/etc/cumin/ssh_config'
    # Ensure to add FQDN of the current host also the first time the role is applied
    $cumin_masters = (wmflib::role::hosts('cluster::management') << $facts['networking']['fqdn']).sort.unique
    $mariadb_roles = Profile::Mariadb::Role
    $mariadb_sections = Profile::Mariadb::Valid_section
    $owners = profile::contacts::get_owners().values.flatten.unique
    $lvs_hosts = wmflib::service::get_lvs_class_hosts()
    $puppetdb_port = 443

    keyholder::agent { 'cumin_master':
        trusted_groups => ['root'],
    }

    stdlib::ensure_packages([
        'clustershell',  # Installs nodeset CLI that is useful to mangle host lists.
        'cumin',
        'python3-dnspython',
        'python3-phabricator',
        'python3-requests',
        'python3-dbg',
        'gnutls-bin' # a bit nicer than curl/openssl for checking local or remote certs
    ])

    file { $cumin_log_path:
        ensure => directory,
        mode   => '0750',
    }

    file { '/etc/cumin':
        ensure => directory,
        mode   => '0755',
    }

    file { '/etc/cumin/config.yaml':
        ensure  => file,
        mode    => '0640',
        content => template('profile/cumin/config.yaml.erb'),
        require => File['/etc/cumin'],
    }

    file { '/etc/cumin/config-installer.yaml':
        ensure  => file,
        mode    => '0640',
        content => template('profile/cumin/config-installer.yaml.erb'),
        require => File['/etc/cumin'],
    }

    file { '/etc/cumin/aliases.yaml':
        ensure  => file,
        mode    => '0644',
        content => template('profile/cumin/aliases.yaml.erb'),
        require => File['/etc/cumin'],
    }

    $check_cumin_aliases_ensure = $email_alerts.bool2str('file', 'absent')
    file { '/usr/local/sbin/check-cumin-aliases':
        ensure => $check_cumin_aliases_ensure,
        source => 'puppet:///modules/profile/cumin/check_cumin_aliases.py',
        mode   => '0544',
    }

    file { '/usr/local/bin/secure-cookbook':
        ensure => file,
        source => 'puppet:///modules/profile/cumin/secure_cookbook.py',
        mode   => '0555',
    }

    # Audit servers in insetup role periodic job
    $insetup_role_report_ensure = ($insetup_role_report_day == 0).bool2str('absent', 'present')
    if $insetup_role_report_ensure == 'present' and $insetup_role_report_config == undef {
        fail('profile::cumin::master::insetup_role_report_config is required when insetup_role_report_day is not 0')
    }

    file { '/usr/local/sbin/insetup-role-report':
        ensure => file,
        source => 'puppet:///modules/profile/cumin/insetup_role_report.py',
        mode   => '0544',
    }

    file { '/etc/cumin/insetup_role_report.json':
        ensure  => stdlib::ensure($insetup_role_report_ensure, 'file'),
        mode    => '0440',
        owner   => 'root',
        group   => 'root',
        content => $insetup_role_report_config.then |$c| { $c.to_json_pretty },
        require => File['/etc/cumin'],
    }

    file { $ssh_config_path:
        ensure => file,
        mode   => '0640',
        source => 'puppet:///modules/profile/cumin/ssh_config',
    }

    # Export service discovery types for Prometheus
    prometheus::node_textfile { 'export_service_type':
        filesource     => 'puppet:///modules/profile/cumin/export_service_type.py',
        # Run every 30 seconds using systemd OnCalendar step for the seconds field
        interval       => '*-*-* *:*:0/30',
        run_cmd        => '/usr/local/bin/export_service_type --outfile /var/lib/prometheus/node.d/discovery_types.prom',
        extra_packages => ['python3-prometheus-client'],
    }

    # Check aliases periodic job, splayed between the week across the Cumin masters
    $times = cron_splay($cumin_masters, 'weekly', 'cumin-check-aliases')
    $check_cumin_aliases_timer_ensure = $email_alerts.bool2str('present', 'absent')
    systemd::timer::job { 'cumin-check-aliases':
        ensure        => $check_cumin_aliases_timer_ensure,
        user          => 'root',
        description   => 'Checks the cumin aliases file for problems.',
        command       => '/usr/local/sbin/check-cumin-aliases',
        send_mail     => $email_alerts,
        send_mail_to  => 'sre-foundations@wikimedia.org',
        ignore_errors => true,
        interval      => { 'start' => 'OnCalendar', 'interval' => $times['OnCalendar'] },
    }

    systemd::timer::job { 'cumin-insetup-role-report':
        ensure        => $insetup_role_report_ensure,
        user          => 'root',
        description   => 'Send an audit report for servers in insetup roles.',
        command       => '/usr/local/sbin/insetup-role-report',
        send_mail     => $email_alerts,
        ignore_errors => true,
        interval      => { 'start' => 'OnCalendar', 'interval' => "*-*-${insetup_role_report_day} 09:42:00" },
    }

    class { 'phabricator::bot':
        username => 'ops-monitoring-bot',
        token    => $passwords::phabricator::ops_monitoring_bot_token,
        owner    => 'root',
        group    => 'root',
    }
}
