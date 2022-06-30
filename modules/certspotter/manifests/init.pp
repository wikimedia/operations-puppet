# SPDX-License-Identifier: Apache-2.0
# == Class: certspotter
#
# Installs and sets up certspotter for the specified domains and runs it
# periodically, sending notifications to a predefined address.
#
# === Parameters
#
# [*alert_email*]
#   An email address to send alerts to.
#
# [*monitor_domains*]
#   An array of domains to monitor certificates for.
#
# === Examples
#
#  class { 'certspotter':
#      alert_email     => 'webmaster@example.org',
#      monitor_domains => [ 'example.com', 'example.org' ],
#  }

class certspotter(
  String              $alert_email,
  Array[Stdlib::Fqdn] $monitor_domains,
) {

    ensure_packages(['certspotter'])

    $homedir = '/var/lib/certspotter'
    $statedir = "${homedir}/state"
    $configdir = '/etc/certspotter'
    $watchlist = "${configdir}/watchlist"
    $ctlogslist = "${configdir}/ctlogslist.json"

    systemd::sysuser { 'certspotter':
        home_dir    => $homedir,
        shell       => '/bin/sh',
        description => 'certspotter user',
    }

    file { $configdir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { $watchlist:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('certspotter/watchlist.erb'),
    }

    file { $ctlogslist:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => file('certspotter/ctlogslist.json'),
    }

    $cmd = "/usr/bin/certspotter -watchlist ${watchlist} -start_at_end -logs ${ctlogslist} -state_dir ${statedir}"
    systemd::timer::job { 'certspotter':
        ensure                  => present,
        description             => 'Run certspotter periodically to monitor for issuance of certificates',
        command                 => $cmd,
        send_mail               => true,
        send_mail_only_on_error => false,
        environment             => { 'MAILTO' => $alert_email },
        user                    => 'certspotter',
        interval                => {'start' => 'OnUnitInactiveSec', 'interval' => '30min'},
        splay                   => fqdn_rand(300, 'certspotter'),
        require                 => [
            User['certspotter'],
            Package['certspotter'],
            File[$watchlist],
        ],
    }

}
