# @summary Shared profile for front- and back-end puppetmasters.
#
# @base_param config:  Dict merged with front- or back- specifics and then passed
#           to ::puppetmaster as $config
#
# @param storeconfigs: Accepts values of 'puppetdb', 'activerecord', and 'none'
# @param puppetdb_hosts list of puppetdb hosts
# @param command_broadcast 
# @param ssl_verify_depth ssl verify depth
# @param netbox_hiera_enable add the netbox-hiera repo
# @param reports list of puppet reports
# @param enable_merge_cli whether to use the puppet-merge tool to manage git updates
# @param hiera_config which hiera configuration file to use
class profile::puppetmaster::common (
                                $base_config,
    Enum['puppetdb', 'none']    $storeconfigs        = lookup('profile::puppetmaster::common::storeconfigs'),
    Array[Stdlib::Host]         $puppetdb_hosts      = lookup('profile::puppetmaster::common::puppetdb_hosts'),
    Boolean                     $command_broadcast   = lookup('profile::puppetmaster::common::command_broadcast'),
    Integer[1,2]                $ssl_verify_depth    = lookup('profile::puppetmaster::common::ssl_verify_depth'),
    Boolean                     $netbox_hiera_enable = lookup('profile::puppetmaster::common::netbox_hiera_enable'),
    Array[Puppetmaster::Report] $reports             = lookup('profile::puppetmaster::common::reports'),
    Boolean                     $enable_merge_cli    = lookup('profile::puppetmaster::common::enable_merge_cli'),
    String[1]                   $hiera_config        = lookup('profile::puppetmaster::common::hiera_config'),
) {
    $env_config = {
        'environmentpath'  => '$confdir/environments',
        'default_manifest' => '$confdir/manifests',
    }

    $activerecord_config =   {
        'storeconfigs'      => true,
        'thin_storeconfigs' => true,
    }

    $puppetdb_config = {
        storeconfigs         => true,
        storeconfigs_backend => 'puppetdb',
        reports              => $reports.join(',')
    }

    if $storeconfigs == 'puppetdb' {
        class { 'puppetmaster::puppetdb::client':
            hosts             => $puppetdb_hosts,
            command_broadcast => $command_broadcast,
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
}
