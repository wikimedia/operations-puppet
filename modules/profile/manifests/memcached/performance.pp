# == Class: profile::memcached::performance
#
# Installs and configures performance settings for the Memcached's host.
#
class profile::memcached::performance {

    # Configure special settings to the NIC
    interface::rps {
        $facts['interface_primary']:
    }
}