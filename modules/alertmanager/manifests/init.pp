# SPDX-License-Identifier: Apache-2.0
class alertmanager (
    Stdlib::Host        $active_host,
    Array[Stdlib::Host] $partners,
    String $irc_channel,
    String $data_retention_time = '730h', # 30 days
    Optional[String] $victorops_api_key = undef,
    Optional[String] $vhost = undef,
    Optional[Boolean] $sink_notifications = false,
) {
    ensure_packages(['prometheus-alertmanager', 'alertmanager-webhook-logger'])

    service { 'prometheus-alertmanager':
        ensure => running,
        enable => true,
    }

    service { 'alertmanager-webhook-logger':
        ensure => running,
        enable => true,
    }

    profile::auto_restarts::service { 'alertmanager-webhook-logger': }

    # Specify a retention time to keep silence history for longer
    $base_args = "--data.retention=${data_retention_time}"

    # Build cluster peers argv with all non-local hostnames
    $all_hosts = $partners + $active_host
    $cluster_opts = $all_hosts.reduce(
      ['--cluster.advertise-address', "${::ipaddress}:9094"]) |$agg, $host| {
        if $host != $::fqdn {
            $tmp = ['--cluster.peer', "${host}:9094"]
        } else {
            $tmp = []
        }
        $agg + $tmp
    }

    if (empty($cluster_opts)) {
        $cluster_args = ''
    } else {
        $cluster_args = join($cluster_opts, ' ')
    }

    $args="${base_args} ${cluster_args}"

    file { '/etc/default/prometheus-alertmanager':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "ARGS=\"${args}\"\n",
        notify  => Service['prometheus-alertmanager'],
    }

    file { '/etc/prometheus/alertmanager.yml':
        ensure       => present,
        owner        => 'prometheus',
        group        => 'root',
        mode         => '0440',
        show_diff    => false,
        content      => template('alertmanager/alertmanager.yml.erb'),
        notify       => Exec['alertmanager-reload'],
        validate_cmd => '/usr/bin/amtool check-config %',
    }

    file { '/etc/prometheus/amtool.yml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('alertmanager/amtool.yml.erb'),
    }

    # Custom email template -- adapted from upstream to adjust for "alert dashboard" links.
    file { '/etc/prometheus/alertmanager_templates/email.tmpl':
        ensure  => present,
        owner   => 'prometheus',
        group   => 'root',
        mode    => '0440',
        content => template('alertmanager/email.tmpl.erb'),
        notify  => Exec['alertmanager-reload'],
    }

    # Custom page-related templates
    file { '/etc/prometheus/alertmanager_templates/page.tmpl':
        ensure  => present,
        owner   => 'prometheus',
        group   => 'root',
        mode    => '0440',
        content => template('alertmanager/page.tmpl.erb'),
        notify  => Exec['alertmanager-reload'],
    }

    exec { 'alertmanager-reload':
        command     => '/bin/systemctl reload prometheus-alertmanager',
        refreshonly => true,
    }
}
