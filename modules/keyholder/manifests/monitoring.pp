# == Class: keyholder::monitoring
#
# Provisions an Icinga check and a Prometheus node.d collector that
# ensures the keyholder is armed with all configured identities.
#
class keyholder::monitoring(
    Wmflib::Ensure $ensure = present,
) {
    file { '/usr/lib/nagios/plugins/check_keyholder':
        ensure => absent,
    }

    nrpe::plugin { 'check_keyholder':
        ensure => absent,
        source => 'puppet:///modules/keyholder/check_keyholder',
    }

    file { '/usr/local/sbin/prometheus-keyholder-exporter':
        ensure => $ensure,
        source => 'puppet:///modules/keyholder/prometheus-keyholder-exporter.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    sudo::user { 'nagios_check_keyholder':
        ensure => absent,
    }

    nrpe::monitor_service { 'keyholder':
        ensure       => absent,
        description  => 'Keyholder SSH agent',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_keyholder',
        sudo_user    => 'root',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Keyholder',
    }

    systemd::timer::job { 'prometheus-keyholder-exporter':
        ensure      => $ensure,
        description => 'Regular job to collect Keyholder armed state as Prometheus metrics',
        user        => 'root',
        command     => '/usr/local/sbin/prometheus-keyholder-exporter',
        interval    => {'start' => 'OnCalendar', 'interval' => 'minutely'},
    }
}
