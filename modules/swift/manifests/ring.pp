class swift::ring (
    $swift_cluster = $swift::params::swift_cluster,
    $storage_policies = $swift::params::storage_policies,
) {
    # lint:ignore:puppet_url_without_modules
    file { '/etc/swift/account.builder':
        ensure    => present,
        source    => "puppet:///volatile/swift/${swift_cluster}/account.builder",
        show_diff => false,
    }

    file { '/etc/swift/account.ring.gz':
        ensure => present,
        source => "puppet:///volatile/swift/${swift_cluster}/account.ring.gz",
    }

    file { '/etc/swift/container.builder':
        ensure    => present,
        source    => "puppet:///volatile/swift/${swift_cluster}/container.builder",
        show_diff => false,
    }

    file { '/etc/swift/container.ring.gz':
        ensure => present,
        source => "puppet:///volatile/swift/${swift_cluster}/container.ring.gz",
    }

    file { '/etc/swift/object.builder':
        ensure    => present,
        source    => "puppet:///volatile/swift/${swift_cluster}/object.builder",
        show_diff => false,
    }

    file { '/etc/swift/object.ring.gz':
        ensure => present,
        source => "puppet:///volatile/swift/${swift_cluster}/object.ring.gz",
    }

    if $storage_policies {
        file { '/etc/swift/object-1.builder':
            ensure    => present,
            source    => "puppet:///volatile/swift/${swift_cluster}/object-1.builder",
            show_diff => false,
        }

        file { '/etc/swift/object-1.ring.gz':
            ensure => present,
            source => "puppet:///volatile/swift/${swift_cluster}/object-1.ring.gz",
        }
    }
    # lint:endignore
}
