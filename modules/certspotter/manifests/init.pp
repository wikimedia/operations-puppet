# == Class: certspotter
#
# Installs and sets up certspotter for the specified domains and runs it
# periodically, sending notifications to a predefined address.
#
# === Parameters
#
# [*domains*]
#   An array of domains to monitor certificates for.
#
# [*address*]
#   An email address to send alerts to.
#
# === Examples
#
#  class { 'certspotter':
#      domains => [ 'example.com', 'example.org' ],
#      address => 'webmaster@example.org',
#  }
#

class certspotter(
  $domains,
  $address,
) {
    package { 'certspotter':
        ensure => present,
    }

    $homedir = '/var/lib/certspotter'
    $statedir = "${homedir}/state"
    $configdir = '/etc/certspotter'
    $watchlist = "${configdir}/watchlist"

    user { 'certspotter':
        ensure     => present,
        home       => $homedir,
        shell      => '/bin/sh',
        comment    => 'certspotter user',
        gid        => 'certspotter',
        system     => true,
        managehome => true,
        require    => Group['certspotter'],
    }

    group { 'certspotter':
        ensure => present,
        system => true,
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
        content => inline_template("<%= @domains.join(\"\n\") %>\n"),
    }

    $cmd = "/usr/bin/certspotter -watchlist ${watchlist} -state_dir ${statedir}"
    cron { 'certspotter':
        command     => "${cmd} >/dev/null 2>&1",
        environment => "MAILTO=${address}",
        user        => 'certspotter',
        minute      => fqdn_rand(30, 'certspotter'),
        hour        => '*',
        require     => [
            User['certspotter'],
            Package['certspotter'],
            File[$watchlist],
        ],
    }

}
