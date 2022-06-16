# SPDX-License-Identifier: Apache-2.0
# Service Discovery for Pontoon

# The module takes care of mapping service names to a single load balancer address.

# The implementation uses a local dnsmasq instance configured with:
# - upstream resolvers, $nameservers
# - an hosts file, with service records generated from $services_config and
#   pointing to $lb_address

# dnsmasq will listen on 127.0.0.53 for DNS queries only, service records are synthetized
# as if services are deployed in all domains. Queries for unknown records will be sent to the
# upstream resolvers instead.

class pontoon::sd (
    Stdlib::IP::Address $lb_address,
    Array[Stdlib::IP::Address] $nameservers,
    Hash[String, Wmflib::Service] $services_config,
) {
    package { 'dnsmasq':
        ensure => installed,
    }

    $services = pontoon::service_names($services_config)

    file { '/etc/pontoon-sd':
        ensure => directory,
    }

    file { '/etc/pontoon-sd/resolv':
        content => template('pontoon/dnsmasq.resolv'),
        notify  => Exec['dnsmasq-reload'],
    }

    file { '/etc/pontoon-sd/hosts':
        content => template('pontoon/dnsmasq.hosts'),
        notify  => Exec['dnsmasq-reload'],
    }

    file { '/etc/dnsmasq.d/pontoon-sd.conf':
        content => template('pontoon/dnsmasq.conf'),
        notify  => Service['dnsmasq'],
    }

    service { 'dnsmasq':
        ensure  => running,
        require => Package['dnsmasq'],
    }

    exec { 'dnsmasq-reload':
        command     => '/bin/systemctl reload dnsmasq',
        refreshonly => true,
    }
}
