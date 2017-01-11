# == Class authdns::lint
# A class to lint Wikimedia's authoritative DNS system
#
class authdns::lint {
    include ::authdns::scripts
    include ::geoip

    package { 'gdnsd':
        ensure => installed,
    }

    service { 'gdnsd':
        ensure     => 'stopped',
        enable     => false,
        hasrestart => true,
        hasstatus  => true,
        require    => Package['gdnsd'],
    }
}
