# SPDX-License-Identifier: Apache-2.0
class alertmanager (
    Stdlib::Host        $active_host,
    Array[Stdlib::Host] $partners,
    String $irc_channel,
    Optional[String] $victorops_api_key = undef,
    Optional[String] $vhost = undef,
) {
    ensure_packages(['prometheus-alertmanager', 'alertmanager-webhook-logger'])

    service { 'prometheus-alertmanager':
        ensure => running,
    }

    service { 'alertmanager-webhook-logger':
        ensure => running,
    }

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
        $args = ''
    } else {
        $args = join($cluster_opts, ' ')
    }

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

    # Custom email template -- adapted from upstream to adjust for "alert dashboard" links.
    file { '/etc/prometheus/alertmanager_templates/email.tmpl':
        ensure    => present,
        owner     => 'prometheus',
        group     => 'root',
        mode      => '0440',
        show_diff => false,
        content   => template('alertmanager/email.tmpl.erb'),
        notify    => Exec['alertmanager-reload'],
    }

    exec { 'alertmanager-reload':
        command     => '/bin/systemctl reload prometheus-alertmanager',
        refreshonly => true,
    }
}
