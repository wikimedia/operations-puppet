# === Class contint::packages::apt
#
# Apt configuration needed for contint hosts
#
class contint::packages::apt {
    include ::apt::unattendedupgrades

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

        # Packages from experimental are explicitly pinned
        apt::pin { 'wikimedia-experimental-lowest-priority':
            package  => '*',
            pin      => 'release o=Wikimedia,c=experimental',
            priority => 1,
        }
    }


}
