class strongswan {
    case $::realm {
        'labs': {
            $fqdn_pem = "${ec2_instance_id}.${domain}.pem"
        }
        'production': {
            $fqdn_pem = "${fqdn}.pem"
        }
    }

    # used in template to enumerate hosts
    # we should probably use hiera instead
    require role::cache::configuration

    package { [ 'strongswan', 'ipsec-tools' ]:
    	ensure => present,
    }

    file { '/etc/ipsec.secrets':
    	content => template('strongswan/ipsec.secrets.erb'),
    	owner => 'root',
    	group => 'root',
    	mode => '600',
    	notify => Service['strongswan'],
    	require => Package['strongswan'],
    }

    file { '/etc/ipsec.conf':
    	content => template('strongswan/ipsec.conf.erb'),
    	owner => 'root',
    	group => 'root',
    	mode => '644',
    	notify => Service['strongswan'],
    	require => Package['strongswan'],
    }

    file { "/etc/ipsec.d/cacerts/ca.pem":
        ensure => present,
        source => "/var/lib/puppet/ssl/certs/ca.pem",
    	notify => Service['strongswan'],
    	require => Package['strongswan'],
    }

    file { "/etc/ipsec.d/certs/${fqdn_pem}":
        ensure => present,
        source => "/var/lib/puppet/ssl/certs/${fqdn_pem}",
    	notify => Service['strongswan'],
    	require => Package['strongswan'],
    }

    file { "/etc/ipsec.d/private/${fqdn_pem}":
        ensure => present,
        source => "/var/lib/puppet/ssl/private_keys/${fqdn_pem}",
    	notify => Service['strongswan'],
    	require => Package['strongswan'],
    }

    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '14.04') >= 0 {
        # for the purpose of this puppet module I have named the service strongswan because ipsec is ambiguous
        service { 'strongswan':
            # in Ubuntu/Trusty this service is /etc/init/strongswan.conf
            ensure => running,
            enable => true,
            hasstatus => true,
            hasrestart => true,
            # upstart service is called strongswan but the IKEv2 daemon itself is called "charon"
            pattern => "charon",
        }
    }
    else {
        service { 'strongswan':
            # in Ubuntu/Preciase and Debian/Jessie this service is /etc/init.d/ipsec
            name => 'ipsec',
            ensure => running,
            enable => true,
            hasstatus => true,
            hasrestart => true,
            # upstart service is called strongswan but the IKEv2 daemon itself is called "charon"
            pattern => "charon",
        }
    }
}
