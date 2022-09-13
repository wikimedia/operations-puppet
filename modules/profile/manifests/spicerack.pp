# @summary Installs the spicerack library and cookbook entry point and their configuration.
#
# @param tcpircbot_host Hostname for the IRC bot.
# @param tcpircbot_port Port to use with the IRC bot.
# @param http_proxy a http_proxy to use for connections
# @param netbox_api the url for the netbox api
# @param redis_shards A hash of Redis shards, with the top level key `sessions`, containing a hash
#   keyed by data center, and then by shard name, each shard having a host and port
#   key.
# @param netbox_token_ro The readonly token for netbox
# @param netbox_token_rw The read/write token for netbox
# @param ganeti_user A Ganeti RAPI user name for Spicerack to use.
# @param ganeti_password The password for the above user.
# @param ganeti_timeout timeout parameter when talking to ganeti
# @param peeringdb_temp_dir a temp directory to use for peeringdb cache
# @param peeringdb_token_ro The perringdb readonly  token
class profile::spicerack(
    String           $tcpircbot_host     = lookup('tcpircbot_host'),
    Stdlib::Port     $tcpircbot_port     = lookup('tcpircbot_port'),
    String           $http_proxy         = lookup('http_proxy'),
    Stdlib::HTTPUrl  $netbox_api         = lookup('netbox_api_url'),
    Hash             $redis_shards       = lookup('redis::shards'),
    String           $netbox_token_ro    = lookup('profile::netbox::ro_token'),
    String           $netbox_token_rw    = lookup('profile::netbox::rw_token'),
    String           $ganeti_user        = lookup('profile::ganeti::rapi::ro_user'),
    String           $ganeti_password    = lookup('profile::ganeti::rapi::ro_password'),
    Integer          $ganeti_timeout     = lookup('profile::spicerack::ganeti_rapi_timeout'),
    Stdlib::Unixpath $peeringdb_temp_dir = lookup('profile::spicerack::peeringdb_temp_dir'),
    String           $peeringdb_token_ro = lookup('profile::spicerack::peeringdb_ro_token'),
) {
    # Ensure pre-requisite profiles are included
    require profile::conftool::client
    require profile::cumin::master
    require profile::ipmi::mgmt
    require profile::access_new_install

    class { 'service::deploy::common': }
    include passwords::redis

    # Packages required by spicerack cookbooks
    ensure_packages(['python3-dateutil', 'python3-prettytable', 'python3-requests', 'spicerack'])

    $cookbooks_dir = '/srv/deployment/spicerack'

    # Install the cookbooks
    git::clone { 'operations/cookbooks':
        ensure    => 'latest',
        directory => $cookbooks_dir,
    }

    # this directory is created by the debian package however we still manage it to force
    # an auto require on all files under it this directory
    file {'/etc/spicerack':
        ensure  => directory,
        owner   => 'root',
        group   => 'ops',
        mode    => '0550',
        require => Package['spicerack'],
    }

    file { '/etc/spicerack/config.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
        content => template('profile/spicerack/config.yaml.erb'),
    }

    ### SPICERACK MODULES CONFIGURATION FILES

    # Redis-specific configuration
    $redis_sessions_data = {
        'password' => $passwords::redis::main_password,
        'shards' => $redis_shards['sessions'],
    }

    # Ganeti RAPI configuration
    $ganeti_auth_data = {
        'username' => $ganeti_user,
        'password' => $ganeti_password,
        'timeout'  => $ganeti_timeout,
    }

    # Netbox backend configuration
    $netbox_config_data = {
        'api_url'   => $netbox_api,
        'api_token_ro' => $netbox_token_ro,
        'api_token_rw' => $netbox_token_rw,
    }

    # PeeringDB backend configuration
    $peeringdb_config_data = {
        'api_token_ro' => $peeringdb_token_ro,
        'cachedir'     => $peeringdb_temp_dir,
    }

    # Kafka cluster brokers configuration
    $kafka_config_data = {
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
    }

    # Elasticsearch cluster configuration
    $elasticsearch_config_data = {
      'search' => {
        'search_eqiad' => {
          'production-search-eqiad' => 'https://search.svc.eqiad.wmnet:9243',
          'production-search-omega-eqiad' => 'https://search.svc.eqiad.wmnet:9443',
          'production-search-psi-eqiad' => 'https://search.svc.eqiad.wmnet:9643',
        },
        'search_codfw' => {
          'production-search-codfw' => 'https://search.svc.codfw.wmnet:9243',
          'production-search-omega-codfw' => 'https://search.svc.codfw.wmnet:9443',
          'production-search-psi-codfw' => 'https://search.svc.codfw.wmnet:9643',
        },
        'relforge' => {
          'relforge-eqiad' => 'https://relforge1004.eqiad.wmnet:9243',
          'relforge-eqiad-small-alpha' => 'https://relforge1004.eqiad.wmnet:9443',
        },
        'cloudelastic' => {
          'cloudelastic-chi-https' => 'https://cloudelastic.wikimedia.org:9243',
          'cloudelastic-omega-https' => 'https://cloudelastic.wikimedia.org:9443',
          'cloudelastic-psi-https' => 'https://cloudelastic.wikimedia.org:9643',
        },
      },
      'logging' => {
          'logging-eqiad' => 'http://logstash1010.eqiad.wmnet:9200',
          'logging-codfw' => 'http://logstash2001.codfw.wmnet:9200',
      },
    }

    # Install all configuration files
    # Semicolon needed for https://tickets.puppetlabs.com/browse/PUP-10782
    ;{
        'elasticsearch' => { 'config.yaml' => $elasticsearch_config_data },
        'ganeti' => { 'config.yaml' => $ganeti_auth_data },
        'kafka' => { 'config.yaml' => $kafka_config_data },
        'netbox' => { 'config.yaml' => $netbox_config_data },
        'peeringdb' => { 'config.yaml' => $peeringdb_config_data },
        'redis_cluster' => { 'sessions.yaml' => $redis_sessions_data },
        'service' => { 'service.yaml' => wmflib::service::fetch() },
    }.each | $dir, $file_data | {
        file { "/etc/spicerack/${dir}":
            ensure => directory,
            owner  => 'root',
            group  => 'ops',
            mode   => '0550',
        }
        $file_data.each | $filename, $content | {
            file { "/etc/spicerack/${dir}/${filename}":
                ensure  => file,
                owner   => 'root',
                group   => 'ops',
                mode    => '0440',
                content => to_yaml($content),
            }
        }
    }

    ### COOKBOOKS CONFIGURATION FILES

    file { '/etc/spicerack/cookbooks':
        ensure => directory,
        owner  => 'root',
        group  => 'ops',
        mode   => '0550',
    }
    file { '/etc/spicerack/cookbooks/sre.network.cf.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
        content => secret('spicerack/cookbooks/sre.network.cf.yaml'),
    }

    # Configuration file for switching services between datacenters
    # For each discovery record for active-active services, extract the
    # actual dns from monitoring if available.
    $discovery_records = wmflib::service::fetch().filter |$label, $record| {
        $record['discovery'] != undef
    }

    file { '/etc/spicerack/cookbooks/sre.switchdc.services.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
        content => template('profile/spicerack/sre.switchdc.services.yaml.erb'),
    }
}
