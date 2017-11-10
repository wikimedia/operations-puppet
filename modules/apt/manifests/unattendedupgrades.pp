class apt::unattendedupgrades($ensure=present) {
    package { 'unattended-upgrades':
        ensure => $ensure,
    }

    apt::conf { 'auto-upgrades':
        ensure   => $ensure,
        priority => '20',
        key      => 'APT::Periodic::Unattended-Upgrade',
        value    => '1',
    }

    apt::conf { 'unattended-upgrades-wikimedia':
        priority => '51',
        # Key with trailing '::' to append to potentially existing entry
        key      => 'Unattended-Upgrade::Origins-Pattern::',
        # lint:ignore:single_quote_string_with_variables
        value    => 'origin=Wikimedia,codename=${distro_codename}-wikimedia',
        # lint:endignore
    }

    apt::conf { 'unattended-upgrades-updates':
        priority => '52',
        # Key with trailing '::' to append to potentially existing entry
        key      => 'Unattended-Upgrade::Origins-Pattern::',
        # lint:ignore:single_quote_string_with_variables
        value    => 'origin=${distro_id},codename=${distro_codename}-updates',
        # lint:endignore
    }
}
