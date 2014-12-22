class apt::unattendedupgrades($ensure=present) {
    package { 'unattended-upgrades':
        ensure => $ensure,
    }

    # Package update-notifier-common is not available on Jessie.  I'm not
    #  sure what (if anything) we should include instead.
    if os_version('ubuntu > lucid') {
        package { 'update-notifier-common':
            ensure => $ensure,
        }
    }

    apt::conf { 'auto-upgrades':
        ensure   => $ensure,
        priority => '20',
        key      => 'APT::Periodic::Unattended-Upgrade',
        value    => '1',
    }
}
