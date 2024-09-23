# Class: dnsrecursor
#
# Installs and configures PowerDNS Recursor, which is currently used an
# internal recursor and also by Wikidough. The parameters and configuration for
# this module take into account both these use cases.
#
# The PowerDNS specific settings are covered in the recursor.conf.erb file and
# the class parameters are also documented there.
#
# [*listen_addresses]
#  Addresses the DNS recursor should listen on for queries
#
# [*allow_from]
#  Prefixes from which to allow recursive DNS queries
#
# [*do_ipv6*]
#  (bool) Whether to enable IPv6 for outgoing queries. Disabled by default in pdns-recursor.
#
# [*restart_service*]
#  (bool) Specifies if the pdns-recursor service should be restarted when the config file changes
#
# [*allow_extended_errors*]
#  (bool) Specifies if RFC 8914 (EDNS Extended Error) should be enabled in responses


class dnsrecursor (
    Array[Variant[Stdlib::IP::Address, Array[Stdlib::IP::Address]]] $listen_addresses         = [$::ipaddress],
    Boolean                                                         $allow_from_listen        = true,
    Array[Stdlib::IP::Address]                                      $allow_from               = [],
    Boolean                                                         $allow_forward_zones      = true,
    String                                                          $additional_forward_zones = '',
    Optional[String]                                                $auth_zones               = undef,
    Optional[Variant[Stdlib::Unixpath, Array[Stdlib::Unixpath]]]    $lua_hooks                = undef,
    Integer[1]                                                      $max_cache_entries        = 1000000,
    Integer[1]                                                      $max_negative_ttl         = 3600,
    Integer[1]                                                      $max_tcp_clients          = 128,
    Integer[0]                                                      $max_tcp_per_client       = 100,   # 0 means unlimited
    Integer[1]                                                      $client_tcp_timeout       = 2,
    Enum['no', 'off', 'yes']                                        $export_etc_hosts         = 'off', # no and off are the same
    Boolean                                                         $version_hostname         = false,
    Enum['off', 'log-fail', 'validate']                             $dnssec                   = 'off', # T226088 T227415 - off until at least 4.1.x
    Integer[1]                                                      $threads                  = 4,
    Enum['no', 'yes']                                               $log_common_errors        = 'yes',
    Optional[String]                                                $bind_service             = undef,
    Boolean                                                         $allow_edns_whitelist     = true,
    Boolean                                                         $allow_incoming_ecs       = false,
    Boolean                                                         $allow_qname_minimisation = false,
    Boolean                                                         $allow_dot_to_auth        = false,
    Boolean                                                         $allow_edns_padding       = false,
    Optional[Enum['always', 'padded-queries-only']]                 $edns_padding_mode        = undef,
    Optional[Stdlib::IP::Address]                                   $edns_padding_from        = undef,
    Boolean                                                         $do_ipv6                  = false,
    Boolean                                                         $enable_webserver         = false,
    Optional[Stdlib::Port]                                          $webserver_port           = 8082,
    Enum['none', 'normal', 'detailed']                              $webserver_log_level      = 'none',
    Boolean                                                         $restart_service          = true,
    Array[Stdlib::IP::Address]                                      $api_allow_from           = [],
    Array[Stdlib::IP::Address::Nosubnet]                            $query_local_address      = [],
    Boolean                                                         $allow_extended_errors    = false,
) {

    ensure_packages(['pdns-recursor'])

    include network::constants
    $wmf_authdns = [
        '208.80.154.238',
        '208.80.153.231',
        '198.35.27.27',
    ]
    $wmf_authdns_semi = join($wmf_authdns, ';')
    $forward_zones = "wmnet=${wmf_authdns_semi}, 10.in-addr.arpa=${wmf_authdns_semi}, 20.172.in-addr.arpa=${wmf_authdns_semi}, wikimedia.org=${wmf_authdns_semi}"

    $socket_dir = '/var/run/pdns-recursor/'
    $group = 'pdns'

    if $restart_service {
      $service = Service['pdns-recursor']
    } else {
      $service = undef
    }

    file { '/etc/powerdns/recursor.conf':
        ensure  => 'present',
        require => Package['pdns-recursor'],
        owner   => 'root',
        group   => $group,
        mode    => '0440',
        notify  => $service,
        content => template('dnsrecursor/recursor.conf.erb'),
    }

    if $lua_hooks != undef {
        file { '/etc/powerdns/recursorhooks.lua':
            ensure  => 'present',
            require => Package['pdns-recursor'],
            owner   => 'root',
            group   => $group,
            mode    => '0440',
            notify  => Service['pdns-recursor'],
            content => template('dnsrecursor/recursorhooks.lua.erb'),
        }
    }

    systemd::service { 'pdns-recursor':
        ensure   => present,
        override => true,
        restart  => true,
        content  => template('dnsrecursor/override.conf.erb'),
        require  => [
          Package['pdns-recursor'],
          File['/etc/powerdns/recursor.conf']
        ],
    }
}
