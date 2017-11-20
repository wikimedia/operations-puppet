class apt::unattendedupgrades($ensure=present) {
    # package installation should enable security upgrades by default
    package { 'unattended-upgrades':
        ensure => $ensure,
    }

    # dpkg tries to determine the most conservative default action in case of
    # conffile conflict. This tells dpkg to use that action without asking
    apt::conf { 'dpkg-force-confdef':
        ensure   => present,
        priority => '00',
        key      => 'Dpkg::Options::',
        value    => '--force-confdef',
    }

    # In case of conffile conflicts, tell dpkg to keep the old conffile without
    # asking
    apt::conf { 'dpkg-force-confold':
        ensure   => present,
        priority => '00',
        key      => 'Dpkg::Options::',
        value    => '--force-confold',
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
}
