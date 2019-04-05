# == Class: keyholder::monitoring
#
# Provisions an Icinga check that ensures the keyholder is armed
# with all configured identities.
#
class keyholder::monitoring( $ensure = present ) {
    validate_ensure($ensure)

    $plugin_path = '/usr/lib/nagios/plugins/check_keyholder'

    file { $plugin_path:
        ensure => $ensure,
        source => 'puppet:///modules/keyholder/check_keyholder',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    sudo::user { 'nagios_check_keyholder':
        ensure     => $ensure,
        user       => 'nagios',
        privileges => [ "ALL = NOPASSWD: ${plugin_path}" ],
        require    => File[$plugin_path],
    }

    nrpe::monitor_service { 'keyholder':
        ensure       => $ensure,
        description  => 'Keyholder SSH agent',
        nrpe_command => "/usr/bin/sudo ${plugin_path}",
        require      => Sudo::User['nagios_check_keyholder'],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Keyholder',
    }
}
