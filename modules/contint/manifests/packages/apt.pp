# === Class contint::packages::apt
#
# Apt configuration needed for contint hosts
#
class contint::packages::apt {
    class { 'apt::unattendedupgrades':
        ensure => absent,
    }

    apt::conf { 'unattended-upgrades-wikimedia':
        ensure   => absent,
        priority => '51',
        key      => 'Unattended-Upgrade::Allowed-Origins',
        # lint:ignore:single_quote_string_with_variables
        value    => 'Wikimedia:${distro_codename}-wikimedia',
        # lint:endignore
    }
    apt::conf { 'lower-periodic-randomsleep':
        ensure   => absent,
        priority => '51',
        key      => 'APT::Periodic::RandomSleep',
        value    => '300',
    }

    # Not meant to run hourly :/
    file { '/etc/cron.hourly/apt':
        ensure  => absent,
    }
}
