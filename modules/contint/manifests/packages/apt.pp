# === Class contint::packages::apt
#
# Apt configuration needed for contint hosts
#
class contint::packages::apt {
    include apt::unattendedupgrades

    apt::conf { 'unattended-upgrades-wikimedia':
        priority => '51',
        key      => 'Unattended-Upgrade::Allowed-Origins',
        # lint:ignore:single_quote_string_with_variables
        value    => 'Wikimedia:${distro_codename}-wikimedia',
        # lint:endignore
    }

}
