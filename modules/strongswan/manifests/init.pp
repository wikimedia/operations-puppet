class strongswan {
    case $::realm {
        'labs': {
            $wmf_fqdn = "${ec2_instance_id}.${domain}"
        }
        'production': {
            $wmf_fqdn = "${fqdn}"
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

    file { "/etc/ipsec.d/certs/${wmf_fqdn}.pem":
        ensure => present,
        source => "/var/lib/puppet/ssl/certs/${wmf_fqdn}.pem",
    	notify => Service['strongswan'],
    	require => Package['strongswan'],
    }

    file { "/etc/ipsec.d/private/${wmf_fqdn}.pem":
        ensure => present,
        source => "/var/lib/puppet/ssl/private_keys/${wmf_fqdn}.pem",
    	notify => Service['strongswan'],
    	require => Package['strongswan'],
    }

    # in 12.04 and Jessie this service is named ipsec
    service { 'strongswan':
    	ensure => running,
    	enable => true,
    	hasstatus => true,
    	hasrestart => true,
    	# upstart service is called strongswan but the IKEv2 daemon itself is called "charon"
    	pattern => "charon",
    }
}
