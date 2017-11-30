class apt::unattendedupgrades(
    $unattended_distro=true,
    $unattended_wmf=true,
    $unattended_updates=true,
    ) {

    # package installation should enable security upgrades by default
    package { 'unattended-upgrades':
        ensure => 'present',
    }

    # dpkg tries to determine the most conservative default action in case of
    # conffile conflict. This tells dpkg to use that action without asking
    apt::conf { 'dpkg-force-confdef':
        ensure   => 'present',
        priority => '00',
        key      => 'Dpkg::Options::',
        value    => '--force-confdef',
    }

    # In case of conffile conflicts, tell dpkg to keep the old conffile without
    # asking
    apt::conf { 'dpkg-force-confold':
        ensure   => 'present',
        priority => '00',
        key      => 'Dpkg::Options::',
        value    => '--force-confold',
    }

    # Unattended updates for packages from upstream distro
    apt::conf { 'auto-upgrades':
        ensure   => $unattended_distro,
        priority => '20',
        key      => 'APT::Periodic::Unattended-Upgrade',
        value    => '1',
    }

    # Unattended should update WMF packages
    # https://apt.wikimedia.org/wikimedia/
    # https://wikitech.wikimedia.org/wiki/APT_repository
    apt::conf { 'unattended-upgrades-wikimedia':
        ensure   => $unattended_wmf,
        priority => '51',
        # Key with trailing '::' to append to potentially existing entry
        key      => 'Unattended-Upgrade::Origins-Pattern::',
        # lint:ignore:single_quote_string_with_variables
        value    => 'origin=Wikimedia,codename=${distro_codename}-wikimedia',
        # lint:endignore
    }

    # https://wiki.debian.org/StableUpdates
    # https://www.debian.org/News/2011/20110215
    apt::conf { 'unattended-upgrades-updates':
        ensure   => $unattended_updates,
        priority => '52',
        # Key with trailing '::' to append to potentially existing entry
        key      => 'Unattended-Upgrade::Origins-Pattern::',
        # lint:ignore:single_quote_string_with_variables
        value    => 'origin=${distro_id},codename=${distro_codename}-updates',
        # lint:endignore
    }
}
