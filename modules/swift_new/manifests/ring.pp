# XXX support additional storage policies
class swift_new::ring (
    $cluster = $swift_new::params::cluster,
) {
    file { '/etc/swift/account.builder':
        ensure => 'present',
        source => "puppet:///volatile/swift/${cluster}/account.builder",
    }

    file { '/etc/swift/account.ring.gz':
        ensure => 'present',
        source => "puppet:///volatile/swift/${cluster}/account.ring.gz",
    }

    file { '/etc/swift/container.builder':
        ensure => 'present',
        source => "puppet:///volatile/swift/${cluster}/container.builder",
    }

    file { '/etc/swift/container.ring.gz':
        ensure => 'present',
        source => "puppet:///volatile/swift/${cluster}/container.ring.gz",
    }

    file { '/etc/swift/object.builder':
        ensure => 'present',
        source => "puppet:///volatile/swift/${cluster}/object.builder",
    }

    file { '/etc/swift/object.ring.gz':
        ensure => 'present',
        source => "puppet:///volatile/swift/${cluster}/object.ring.gz",
    }
}
