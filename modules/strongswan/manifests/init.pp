class strongswan (
    $puppet_certname = "",
    $hosts           = [],
)
{
    package { [ 'strongswan', 'ipsec-tools' ]:
        ensure => present,
    }

    # On Jessie we need an extra package which is only "recommended"
    # rather than being a strict dependency.
    # If you don't install this, on startup strongswan will say:
    #   loading certificate from 'i-00000894.eqiad.wmflabs.pem' failed
    # and 'pki --verify --in /etc/ipsec.d/certs/i-00000894.eqiad.wmflabs.pem \
    # --ca /etc/ipsec.d/cacerts/ca.pem' will say:
    #  building CRED_CERTIFICATE - X509 failed, tried 3 builders
    #  parsing certificate failed
    if $operatingsystem == "Debian" and $operatingsystemmajrelease >= 8 {
        package { 'libstrongswan-standard-plugins':
            ensure => present,
            before => Service['strongswan']
        }
    }

    file { '/etc/ipsec.secrets':
        content => template('strongswan/ipsec.secrets.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        notify  => Service['strongswan'],
        require => Package['strongswan'],
    }

    file { '/etc/ipsec.conf':
        content => template('strongswan/ipsec.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['strongswan'],
        require => Package['strongswan'],
    }

    # For SSL certs, reuse Puppet client's certs.
    # Strongswan won't accept symlinks, so make copies.

    file { "/etc/ipsec.d/cacerts/ca.pem":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        ensure  => present,
        source  => "/var/lib/puppet/ssl/certs/ca.pem",
        notify  => Service['strongswan'],
        require => Package['strongswan'],
    }

    file { "/etc/ipsec.d/certs/${puppet_certname}.pem":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        ensure  => present,
        source  => "/var/lib/puppet/ssl/certs/${puppet_certname}.pem",
        notify  => Service['strongswan'],
        require => Package['strongswan'],
    }

    file { "/etc/ipsec.d/private/${puppet_certname}.pem":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        ensure  => present,
        source  => "/var/lib/puppet/ssl/private_keys/${puppet_certname}.pem",
        notify  => Service['strongswan'],
        require => Package['strongswan'],
    }

    file { "/usr/local/sbin/ipsec-global":
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        ensure => present,
        source => 'puppet:///modules/strongswan/ipsec-global',
    }

    $svcname = $::lsbdistcodename ? {
        # in Ubuntu/Trusty this service is /etc/init/strongswan.conf
        # in Ubuntu/Precise and Debian/Jessie it's /etc/init.d/ipsec
        'trusty'  => 'strongswan',
        'precise' => 'ipsec',
        'jessie'  => 'ipsec',
        default   => 'ipsec',
    }
    service { 'strongswan':
        ensure     => running,
        enable     => true,
        name       => $svcname,
        pattern    => "charon",  # Strongswan IKEv2 daemon is called charon
        hasstatus  => true,
        hasrestart => true,
    }
}
