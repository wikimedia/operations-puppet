# SPDX-License-Identifier: Apache-2.0

# This profile is injected by the Pontoon ENC and used as the hook
# for code running on all Pontoon hosts.
class profile::pontoon::base (
    Boolean $sd_enabled = lookup('profile::pontoon::sd_enabled', { default_value => false }),
) {
    if $sd_enabled {
        include profile::pontoon::sd
    }

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
}
