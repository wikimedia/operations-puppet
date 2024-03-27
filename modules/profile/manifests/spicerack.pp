# SPDX-License-Identifier: Apache-2.0
# @summary Installs the spicerack library and cookbook entry point and their configuration.
#
# @param tcpircbot_host Hostname for the IRC bot.
# @param tcpircbot_port Port to use with the IRC bot.
# @param http_proxy a http_proxy to use for connections
# @param etcd_config the path to the etcd configuration to use for distributed locking, set empty to disable
# @param netbox_api the url for the netbox api
# @param firmware_store_dir The location to store firmware images
# @param cookbooks_repos key value pair of cookbook repos and the directory to install them to
# @param alertmanager_config_data Alertmanager config data
# @param ganeti_auth_data Ganeti config data
# @param netbox_config_data netbox config data
# @param peeringdb_config_data peeringdb config data
# @param elasticsearch_config_data elastic config data
# @param mysql_config_data MySQL/MariaDB config data
# @param configure_redis if true configure redis
# @param configure_kafka if true configure kafka
# @param cookbooks_dependencies packages needed by specific installed cookbooks
class profile::spicerack (
    String                                 $tcpircbot_host            = lookup('tcpircbot_host'),
    Stdlib::Port                           $tcpircbot_port            = lookup('tcpircbot_port'),
    String                                 $http_proxy                = lookup('http_proxy'),
    Optional[Stdlib::Unixpath]             $etcd_config               = lookup('profile::spicerack::etcd_config'),
    Stdlib::Unixpath                       $firmware_store_dir        = lookup('profile::spicerack::firmware_store_dir'),
    Hash[String, Stdlib::Unixpath]         $cookbooks_repos           = lookup('profile::spicerack::cookbooks_repos'),
    Profile::Spicerack::AlertmanagerConfig $alertmanager_config_data  = lookup('profile::spicerack::alertmanager_config_data'),
    Hash                                   $ganeti_auth_data          = lookup('profile::spicerack::ganeti_auth_data'),
    Hash                                   $netbox_config_data        = lookup('profile::spicerack::netbox_config_data'),
    Hash                                   $peeringdb_config_data     = lookup('profile::spicerack::peeringdb_config_data'),
    Hash                                   $elasticsearch_config_data = lookup('profile::spicerack::elasticsearch_config_data'),
    Hash                                   $mysql_config_data         = lookup('profile::spicerack::mysql_config_data'),
    Hash                                   $authdns_config_data       = lookup('authdns_servers'),
    Boolean                                $configure_kafka           = lookup('profile::spicerack::configure_kafka'),
    Array[String[1]]                       $cookbooks_dependencies    = lookup('profile::spicerack::cookbooks_dependencies', {default_value => []}),
) {
    ensure_packages(['spicerack'] + $cookbooks_dependencies)

    $cookbooks_repos.each |$repo, $dir| {
        wmflib::dir::mkdir_p($dir.dirname)
        git::clone { $repo:
            ensure    => 'latest',
            directory => $dir,
        }
    }

    # Kafka cluster brokers configuration
    $kafka_config_data = $configure_kafka ? {
        true    => {
          'main'   => {
              'eqiad' => kafka_config('main', 'eqiad'),
              'codfw' => kafka_config('main', 'codfw'),
          },
          'jumbo' => {
              'eqiad' => kafka_config('jumbo', 'eqiad'),
          },
          'logging' => {
              'eqiad' => kafka_config('logging', 'eqiad'),
              'codfw' => kafka_config('logging', 'codfw'),
          },
        },
        default => {},
    }

    # This is not pretty and i apologise but there is a wired bug in puppet
    # which munges undef when we pass the hash, best demonstrated with the paste below
    # https://phabricator.wikimedia.org/P42722
    # TODO: refactor this after we move to puppet >= 6
    # or possibly after https://gerrit.wikimedia.org/r/c/operations/puppet/+/868739
    $modules = {
        'alertmanager'  => { 'config.yaml'  => $alertmanager_config_data },
        'elasticsearch' => { 'config.yaml'  => $elasticsearch_config_data },
        'ganeti'        => { 'config.yaml'  => $ganeti_auth_data },
        'kafka'         => { 'config.yaml'  => $kafka_config_data },
        'netbox'        => { 'config.yaml'  => $netbox_config_data },
        'peeringdb'     => { 'config.yaml'  => $peeringdb_config_data },
        'mysql'         => { 'config.yaml'  => $mysql_config_data },
        'service'       => { 'service.yaml' => wmflib::service::fetch() },
        'discovery'     => { 'authdns.yaml' => $authdns_config_data },
    }.filter |$module, $config| { !$config.values[0].empty }

    class { 'spicerack':
        tcpircbot_host => $tcpircbot_host,
        tcpircbot_port => $tcpircbot_port,
        http_proxy     => $http_proxy,
        etcd_config    => $etcd_config,
        cookbooks_dirs => $cookbooks_repos.values,
        modules        => $modules,
    }

    $test_cookbook_config = {
        'cookbook_repos' => $cookbooks_repos.keys,
    }

    file { '/etc/test-cookbook.yaml':
        ensure  => file,
        content => $test_cookbook_config.to_yaml(),
    }

    file { '/usr/local/bin/test-cookbook':
        ensure => file,
        source => 'puppet:///modules/profile/spicerack/test_cookbook.py',
        mode   => '0555',
    }
}
