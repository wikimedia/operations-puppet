# Hook point for Pontoon in base

class profile::pontoon::base (
    Boolean $enabled = lookup('profile::pontoon::base::enabled', { default_value => false }),
    Boolean $sd_enabled = lookup('profile::pontoon::sd_enabled', { default_value => false }),
) {
    if $enabled {
        if $sd_enabled {
            class { 'profile::pontoon::sd':
                # XXX explain
                before => Class['Profile::Resolving'],
            }
        }

        # PKI is used by puppetdb and thus required in most situations.
        # Therefore to make bootstrap 'smaller' it is not required to have
        # a load balancer and service discovery enabled.
        $pki_hosts = pontoon::hosts_for_role('pki::multirootca')
        if $pki_hosts and length($pki_hosts) > 0 {
            host { 'pki.discovery.wmnet':
                ip => ipresolve($pki_hosts[0]),
            }
        }
    }
}
