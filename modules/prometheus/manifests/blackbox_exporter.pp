# Prometheus black box metrics exporter. See also
# https://github.com/prometheus/blackbox_exporter
#
# This does 'active' checks over TCP / UDP / ICMP / HTTP / DNS
# and reports status to the prometheus scraper

class prometheus::blackbox_exporter{

    # Grant permissions to send out ICMP probes
    debconf::set { 'prometheus-blackbox-exporter/want_cap_net_raw':
        type   => 'boolean',
        value  => true,
        before => Package['prometheus-blackbox-exporter'],
    }

    package { 'prometheus-blackbox-exporter':
        ensure => present,
    }

    file { '/etc/prometheus/blackbox.yml.d':
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { '/usr/local/bin/blackbox-exporter-assemble':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/blackbox_exporter/assemble_config.py',
        before => Exec['assemble blackbox.yml'],
    }

    ['misc', 'common'].each |$frag| {
        file { "/etc/prometheus/blackbox.yml.d/${frag}.yml":
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => template("prometheus/blackbox_exporter/${frag}.yml.erb"),
            notify  => Exec['assemble blackbox.yml'],
        }
    }

    # The exec is always run (gated by onlyif) to be able to recover from the following scenario:
    # - a fragment changes, a refresh of this exec is triggered
    # - the exec fails for some reason, the configuration is not updated
    # - at the next puppet run the fragment doesn't change, therefore the exec is not refreshed again
    # - the old configuration is silently kept in place until a fragment changes again

    exec { 'assemble blackbox.yml':
        onlyif  => 'blackbox-exporter-assemble --onlyif',
        command => 'blackbox-exporter-assemble',
        notify  => Service['prometheus-blackbox-exporter'],
        path    => '/usr/local/bin',
    }

    service { 'prometheus-blackbox-exporter':
        ensure     => running,
        hasrestart => true,
        provider   => 'systemd',
    }
}
