# SPDX-License-Identifier: Apache-2.0
# profile::mail::smarthost - configure an outbound smarthost
#
# * $dkim_domains     - DKIM signing specifics. More than one may be supplied
#                         * domain: the domain upon whcih dkim should be enabled for signing outgoing messages
#                         * selector: the dkim selector which should be used for this domain
#                         * exim_router_condition: an option condition to be added to the exim router configuration.
#                                                  useful when multiple selectors exist within the same domain.
#                         * example: { wikimedia => { domain => 'wikimedia.org',
#                                                     selector => 'wikimedia' },
#                                      wiki-mail => { domain => 'wikimedia.org',
#                                                     selector => 'wiki-mail',
#                                                     exim_router_condition => '${if match_ip{$interface_address}{1.2.3.4}' } }
#
# * $cert_name        - The certificate name CN as used by let's encrypt
#
# * $cert_subject     - Subject alternate names to be applied to above certificate
#
# * $relay_from_hosts - An array of CIDR network/host addresses from which mail is to be accepted
#
# * $envelope_rewrite_rules   - An array of envelope rewrite rules to be applied to this smarthost
#
# * $root_alias_rcpt          - The desired recipient (email address) of email to root@local_domains
#
# * $exim_primary_hostname    - The desired hostname of the exim mail system.  Useful if hostname is within .wmflabs

class profile::mail::smarthost (
    $dkim_domains             = lookup('profile::mail::smarthost::dkim_domains', {'default_value' => []}),
    $cert_name                = lookup('profile::mail::smarthost::cert_name', {'default_value' => $facts['hostname']}),
    $relay_from_hosts         = lookup('profile::mail::smarthost::relay_from_hosts', {'default_value' => []}),
    $envelope_rewrite_rules   = lookup('profile::mail::smarthost::envelope_rewrite_rules', {'default_value' => []}),
    $root_alias_rcpt          = lookup('profile::mail::smarthost::root_alias_rcpt', {'default_value' => ':blackhole:'}),
    $exim_primary_hostname    = lookup('profile::mail::smarthost::exim_primary_hostname', {'default_value' => $facts['fqdn']}),
    Boolean $support_ipv6     = lookup('profile::mail::smarthost::support_ipv6', {default_value => true}),
) {

    class { 'exim4':
        variant => 'light',
        config  => template('profile/exim/exim4.conf.smarthost.erb'),
    }

    firewall::service { 'exim-smtp':
        proto => 'tcp',
        port  => 25,
    }

    mailalias { 'root':
        recipient => $root_alias_rcpt,
    }

    file { '/etc/exim4/bounce_message_file':
        ensure => present,
        owner  => 'root',
        group  => 'Debian-exim',
        mode   => '0444',
        source => 'puppet:///modules/profile/exim/bounce_message_file',
    }

    file { '/etc/exim4/warn_message_file':
        ensure => present,
        owner  => 'root',
        group  => 'Debian-exim',
        mode   => '0444',
        source => 'puppet:///modules/profile/exim/warn_message_file',
    }

    $dkim_domains.each |$name, $dkim_domain| {
        $selectors = [$dkim_domain['selector']].flatten
        $selectors.each |String[1] $selector| {
            exim4::dkim { "${name}-${selector}":
                domain   => $dkim_domain['domain'],
                selector => $selector,
                content  => secret("dkim/${dkim_domain['domain']}-${selector}.key"),
            }
        }
    }

    acme_chief::cert { $cert_name:
        key_group  => 'Debian-exim',
        puppet_svc => 'exim4',
    }

    mtail::program { 'exim':
        ensure => present,
        notify => Service['mtail'],
        source => 'puppet:///modules/mtail/programs/exim.mtail',
    }

    # Customize logrotate settings to support longer retention (T167333)
    logrotate::conf { 'exim4-base':
        ensure => 'present',
        source => 'puppet:///modules/profile/exim/logrotate/exim4-base.mx',
    }

    # monitor mail queue size (T133110)
    nrpe::plugin { 'check_exim_queue':
        source => 'puppet:///modules/icinga/check_exim_queue.sh',
    }

    # sudo rule to used by monitoring check
    ::sudo::user { 'nagios_exim_queue':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/sbin/exipick -bpc -o [[\:digit\:]][[\:digit\:]][mh]'],
    }

    monitoring::service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp_tls_le',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mail#Troubleshooting',
    }

    nrpe::monitor_service { 'check_exim_queue':
        description    => 'exim queue',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_exim_queue -w 1000 -c 3000',
        check_interval => 30,
        retry_interval => 10,
        timeout        => 20,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Mail#Troubleshooting',
    }

}
