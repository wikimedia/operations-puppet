# SPDX-License-Identifier: Apache-2.0

# This profile is injected by the Pontoon ENC and used as the hook
# for code running on all Pontoon hosts.
class profile::pontoon::base (
    String  $provider   = lookup('profile::pontoon::provider', { default_value => 'cloud_vps' }),
    Boolean $sd_enabled = lookup('profile::pontoon::sd_enabled', { default_value => false }),
    Boolean $pki_enabled = lookup('profile::puppetserver::pontoon::pki_enabled', { default_value => false }),
    Cfssl::Ca_name $root_ca_name = lookup('profile::pki::root_ca::common_name', {'default_value' => ''})
) {
    ensure_packages(['wmf-certificates'])

    include "profile::pontoon::provider::${provider}"
    include profile::monitoring

    if $sd_enabled {
        include profile::pontoon::sd
    }

    # Partial duplication/compatibility with profile::base::production
    # Ideally Pontoon runs with profile::base::production enabled, and we are
    # not there yet.
    include profile::monitoring
    include profile::rsyslog::kafka_shipper

    if $pki_enabled {
        # PKI is a "base" service, often required even in minimal stacks (e.g.
        # puppetdb can use PKI) which don't necessarily have or want load
        # balancing and service discovery.
        # Therefore register pki as available and route it to the multirootca host.
        $pki_hosts = pontoon::hosts_for_role('pki::multirootca')
        if $pki_hosts != undef {
            host { 'pki.discovery.wmnet':
                ip => ipresolve($pki_hosts[0]),
            }
        }

        # Trust Pontoon Root PKI
        if find_file('/etc/pontoon/pki/ca.pem') {
            file { '/usr/share/ca-certificates/wikimedia/pontoon-pki.crt':
                ensure  => present,
                content => file('/etc/pontoon/pki/ca.pem'),
                notify  => Exec['reconfigure-wmf-certificates'],
                require => Package['wmf-certificates'],
            }

            # This is cheeky but necessary to give that production look and feel:
            # Replace the Puppet CA (and PKI) public certs with Pontoon's, since
            # that's what the user expect (i.e. these two certs will 'just work')
            # and the filenames must be compatible with what will work in production
            if $root_ca_name != '' {
                file { "/usr/share/ca-certificates/wikimedia/${root_ca_name}.crt":
                    ensure  => present,
                    content => file('/etc/pontoon/pki/ca.pem'),
                    notify  => Exec['reconfigure-wmf-certificates'],
                }
            }
        }
    }

    # Trust the Pontoon Puppet CA
    # In theory this could be handled via profile::base::certificates::trusted_certs
    # however there isn't a mechanism to optionally include a cert (i.e.
    # when PKI isn't enabled)
    file { '/usr/share/ca-certificates/wikimedia/pontoon-puppet.crt':
        ensure => present,
        source => '/var/lib/puppet/ssl/certs/ca.pem',
        notify => Exec['reconfigure-wmf-certificates'],
    }

    # Include en_US.UTF-8 which is generated by debian-installer in wikiprod hosts
    include profile::locales::base

    exec { 'reconfigure-wmf-certificates':
        command     => '/usr/sbin/dpkg-reconfigure wmf-certificates',
        refreshonly => true,
        require     => Package['wmf-certificates'],
    }
}
