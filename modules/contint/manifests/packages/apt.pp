# === Class contint::packages::apt
#
# Apt configuration needed for contint hosts
#
class contint::packages::apt {
    include ::apt::unattendedupgrades

    apt::conf { 'unattended-upgrades-wikimedia':
        priority => '51',
        # Key with trailing '::' to append to potentially existing entry
        key      => 'Unattended-Upgrade::Allowed-Origins::',
        # lint:ignore:single_quote_string_with_variables
        value    => 'Wikimedia:${distro_codename}-wikimedia',
        # lint:endignore
    }

    if os_version('debian == jessie') {
        # Sanity check: only enable in labs
        requires_realm('labs')
        # Enable deb.sury.org PHP packages for jessie only
        apt::repository { 'sury-php':
            uri        => 'https://packages.sury.org/php/',
            dist       => $::lsbdistcodename,
            components => 'main',
            source     => false,
            keyfile    => 'puppet:///modules/contint/sury-php.gpg',
        }
    }


}
