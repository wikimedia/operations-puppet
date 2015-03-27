# XXX support additional storage policies
class swift_new::ring (
    $swift_cluster = $swift_new::params::swift_cluster,
) {
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
}
