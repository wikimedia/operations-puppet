# SPDX-License-Identifier: Apache-2.0

# This profile is injected by the Pontoon ENC and used as the hook
# for code running on all Pontoon hosts.
class profile::pontoon::base (
    String  $provider   = lookup('profile::pontoon::provider', { default_value => 'cloud_vps' }),
    Boolean $sd_enabled = lookup('profile::pontoon::sd_enabled', { default_value => false }),
    Boolean $pki_enabled = lookup('profile::puppetmaster::pontoon::pki_enabled', { default_value => false }),
) {
    if $sd_enabled {
        include profile::pontoon::sd
    }

    include "profile::pontoon::provider::${provider}"

    # PKI is a "base" service, often required even in minimal stacks
    # (e.g. puppetdb can use PKI).
    # Do not require a load balancer and service discovery enabled
    # to be able to use PKI.
    $pki_hosts = pontoon::hosts_for_role('pki::multirootca')
    if $pki_hosts and length($pki_hosts) > 0 {
        host { 'pki.discovery.wmnet':
            ip => ipresolve($pki_hosts[0]),
        }
    }

    # Generate en_US.UTF-8. In production debian-installer handles this via:
    # d-i debian-installer/locale  string  en_US
    file_line { 'locale-en_US.UTF-8':
        ensure => present,
        path   => '/etc/locale.gen',
        line   => 'en_US.UTF-8 UTF-8',
        notify => Exec['base-locale-gen'],
    }

    exec { 'base-locale-gen':
        command     => '/usr/sbin/locale-gen --purge',
        refreshonly => true,
    }

    # Trust the Pontoon Puppet CA (and optionally PKI)
    # In theory this could be handled via profile::base::certificates::trusted_certs
    # however there isn't a mechanism to optionally include a cert (i.e.
    # when PKI isn't enabled)
    ensure_packages(['wmf-certificates'])

    file { '/usr/share/ca-certificates/wikimedia/pontoon_puppet_ca.crt':
        ensure => present,
        source => '/var/lib/puppet/ssl/certs/ca.pem',
        notify => Exec['reconfigure-wmf-certificates'],
    }

    if $pki_enabled {
        file { '/usr/share/ca-certificates/wikimedia/pontoon_pki_ca.crt':
            ensure  => present,
            content => file('/etc/pontoon/pki/ca.pem'),
            notify  => Exec['reconfigure-wmf-certificates'],
        }
    }

    exec { 'reconfigure-wmf-certificates':
        command     => '/usr/sbin/dpkg-reconfigure wmf-certificates',
        refreshonly => true,
        require     => Package['wmf-certificates'],
    }
}
