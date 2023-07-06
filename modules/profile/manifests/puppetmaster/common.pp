# SPDX-License-Identifier: Apache-2.0
# @summary Shared profile for front- and back-end puppetmasters.
#
# @param base_config  Dict merged with front- or back- specifics and then passed
#           to ::puppetmaster as $config
# @param storeconfigs Accepts values of 'puppetdb', 'activerecord', and 'none'
# @param puppetdb_hosts list of puppetdb hosts
# @param command_broadcast
# @param ssl_verify_depth ssl verify depth
# @param netbox_hiera_enable add the netbox-hiera repo
# @param reports list of puppet reports
# @param enable_merge_cli whether to use the puppet-merge tool to manage git updates
# @param hiera_config which hiera configuration file to use
# @param disable_env_config disable environments config
class profile::puppetmaster::common (
    Hash         $base_config              = lookup('profile::puppetmaster::common::base_config'),
    Boolean      $command_broadcast        = lookup('profile::puppetmaster::common::command_broadcast'),
    Integer[1,2] $ssl_verify_depth         = lookup('profile::puppetmaster::common::ssl_verify_depth'),
    Boolean      $netbox_hiera_enable      = lookup('profile::puppetmaster::common::netbox_hiera_enable'),
    Boolean      $enable_merge_cli         = lookup('profile::puppetmaster::common::enable_merge_cli'),
    Boolean      $disable_env_config       = lookup('profile::puppetmaster::common::disable_env_config'),
    String[1]    $hiera_config             = lookup('profile::puppetmaster::common::hiera_config'),
    Enum['puppetdb', 'none'] $storeconfigs = lookup('profile::puppetmaster::common::storeconfigs'),
    Array[Puppetmaster::Report] $reports   = lookup('profile::puppetmaster::common::reports'),
    Array[Stdlib::Host] $puppetdb_hosts    = lookup('profile::puppetmaster::common::puppetdb_hosts'),
    Array[Stdlib::HTTPSUrl] $puppetdb_submit_only_hosts = lookup('profile::puppetmaster::common::puppetdb_submit_only_hosts'),
) {
    $env_config = $disable_env_config ? {
        true    => {},
        default => {
            'environmentpath'  => '$confdir/environments',
            'default_manifest' => '$confdir/manifests',
        }
    }

    $activerecord_config =   {
        'storeconfigs'      => true,
        'thin_storeconfigs' => true,
    }

    $puppetdb_config = {
        storeconfigs         => true,
        storeconfigs_backend => 'puppetdb',
        reports              => $reports.join(','),
    }

    if $storeconfigs == 'puppetdb' {
        class { 'puppetmaster::puppetdb::client':
            hosts             => $puppetdb_hosts,
            command_broadcast => $command_broadcast,
            submit_only_hosts => $puppetdb_submit_only_hosts,
        }
        $config = merge($base_config, $puppetdb_config, $env_config)
    } else {
        $config = merge($base_config, $env_config)
    }

    # Don't attempt to use puppet-master service, we're using passenger.
    # TODO: I think we can probably drop this need to check for jessie pms in cloud
    service { 'puppet-master':
        ensure  => stopped,
        enable  => false,
        require => Package['puppet'],
    }

    # Clean up facts for idle hosts. This is just a cache so there's no danger of
    #  premature deletion.
    systemd::timer::job { 'puppet_fact_cleanup':
        ensure      => absent,
        description => 'clean up fact cache for absent hosts',
        user        => 'puppet',
        command     => "/usr/bin/find  /var/lib/puppet/yaml -mtime +7 -exec rm {} \\;",
        interval    => {'start' => 'OnCalendar', 'interval' => 'daily'},
    }

    # Clean up reports for idle hosts. This is just a cache so there's no danger of
    #  premature deletion.
    systemd::timer::job { 'puppet_report_cleanup':
        ensure      => absent,
        description => 'clean up puppet reports cache for absent hosts',
        user        => 'puppet',
        command     => "/usr/bin/find  /var/lib/puppet/reports -mtime +14 -exec rm {} \\;",
        interval    => {'start' => 'OnCalendar', 'interval' => 'daily'},
    }

    include profile::ssh::ca
}
