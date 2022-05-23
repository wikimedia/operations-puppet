# == Class: keyholder::monitoring
#
# Provisions an Icinga check that ensures the keyholder is armed
# with all configured identities.
#
class keyholder::monitoring(
    Wmflib::Ensure $ensure = present,
) {
    file { '/usr/lib/nagios/plugins/check_keyholder':
        ensure => absent,
    }

    nrpe::plugin { 'check_keyholder':
        ensure => $ensure,
        source => 'puppet:///modules/keyholder/check_keyholder',
    }

    sudo::user { 'nagios_check_keyholder':
        ensure => absent,
    }

    nrpe::monitor_service { 'keyholder':
        ensure       => $ensure,
        description  => 'Keyholder SSH agent',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_keyholder',
        sudo_user    => 'root',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Keyholder',
    }
}
