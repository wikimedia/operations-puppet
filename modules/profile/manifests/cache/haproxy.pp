# SPDX-License-Identifier: Apache-2.0
class profile::cache::haproxy (
    String                                   $cache_cluster               = lookup('cache::cluster'),
    Stdlib::Port                             $tls_port                    = lookup('profile::cache::haproxy::tls_port'),
    Stdlib::Port                             $prometheus_port             = lookup('profile::cache::haproxy::prometheus_port', { 'default_value'             => 9422 }),
    Hash[String, Haproxy::Tlscertificate, 1] $available_certificates      = lookup('profile::cache::haproxy::available_certificates'),
    Array[String, 1]                         $enabled_certificates        = lookup('profile::cache::haproxy::enabled_certificates'),
    Haproxy::Backend                         $backend                     = lookup('profile::cache::haproxy::varnish_socket'),
    String                                   $tls_ciphers                 = lookup('profile::cache::haproxy::tls_ciphers'),
    String                                   $tls13_ciphers               = lookup('profile::cache::haproxy::tls13_ciphers'),
    Integer[0]                               $tls_cachesize               = lookup('profile::cache::haproxy::tls_cachesize'),
    Integer[0]                               $tls_session_lifetime        = lookup('profile::cache::haproxy::tls_session_lifetime'),
    Haproxy::Timeout                         $timeout                     = lookup('profile::cache::haproxy::timeout'),
    Haproxy::H2settings                      $h2settings                  = lookup('profile::cache::haproxy::h2settings'),
    Optional[Haproxy::Proxyprotocol]         $proxy_protocol              = lookup('profile::cache::haproxy::proxy_protocol', { 'default_value'              => undef }),
    Boolean                                  $http_disable_keepalive      = lookup('profile::cache::haproxy::http_disable_keepalive', { 'default_value'      => false }),
    Stdlib::Unixpath                         $mtail_dir                   = lookup('profile::cache::haproxy::mtail_dir', { 'default_value'                   => '/etc/haproxymtail' }),
    Stdlib::Port::User                       $mtail_port                  = lookup('profile::cache::haproxy::mtail_port', { 'default_value'                  => 3906 }),
    Stdlib::Unixpath                         $mtail_fifo                  = lookup('profile::cache::haproxy::mtail_fifo', { 'default_value'                  => '/var/log/haproxy.fifo' }),
    Boolean                                  $monitoring_enabled          = lookup('profile::cache::haproxy::monitoring_enabled'),
    Haproxy::Version                         $haproxy_version             = lookup('profile::cache::haproxy::version', { 'default_value'                     => 'haproxy28' }),
    Boolean                                  $do_systemd_hardening        = lookup('profile::cache::haproxy::do_systemd_hardening', { 'default_value'        => false }),
    Boolean                                  $enable_coredumps            = lookup('profile::cache::haproxy::enable_coredumps', { 'default_value'            => false }),
    Boolean                                  $enable_mlock                = lookup('profile::cache::haproxy::enable_mlock', { 'default_value'                => false }),
    Stdlib::Port                             $http_redirection_port       = lookup('profile::cache::haproxy::http_redirection_port', { 'default_value'       => 80 }),
    Optional[Haproxy::Timeout]               $redirection_timeout         = lookup('profile::cache::haproxy::redirection_timeout', { 'default_value'         => undef }),
    Optional[Array[Haproxy::Filter]]         $filters                     = lookup('profile::cache::haproxy::filters', { 'default_value'                     => undef }),
    Boolean                                  $dedicated_hc_backend        = lookup('profile::cache::haproxy::dedicated_hc_backend', { 'default_value'        => false }),
    Boolean                                  $use_haproxykafka            = lookup('profile::cache::haproxy::use_haproxykafka', { 'default_value'            => false }),
    Stdlib::Unixpath                         $haproxykafka_socket         = lookup('profile::cache::haproxy::haproxykafka_socket', { 'default_value'         => '/var/run/haproxykafka/haproxykafka.sock' }),
    Optional[Array[Stdlib::IP::Address]]     $hc_sources                  = lookup('haproxy_allowed_healthcheck_sources', { 'default_value'                  => undef }),
    Optional[Integer]                        $log_length                  = lookup('profile::cache::haproxy::log_length', { 'default_value'                  => 8192 }),
    Boolean                                  $use_etcd_req_filters        = lookup('profile::cache::haproxy::use_etcd_req_filters', { 'default_value'        => false }),
    Boolean                                  $numa_networking             = lookup('profile::cache::haproxy::numa_networking', { 'default_value'             => true }),
    Boolean                                  $use_benthos                 = lookup('profile::cache::haproxy::use_benthos', { 'default_value'                 => true }),
    String                                   $benthos_socket              = lookup('profile::cache::haproxy::benthos_socket_address', { 'default_value'      => '127.0.0.1:1221' }),
    String                                   $conftool_prefix             = lookup('conftool_prefix'),
    Boolean                                  $use_tls_tmpfiles            = lookup('profile::cache::haproxy::use_tls_tmpfiles', { 'default_value'            => false }),
    Array[Wmflib::HTTP::Method]              $allowed_methods             = lookup('profile::cache::haproxy::allowed_methods', { 'default_value'             => ['GET','HEAD','OPTIONS'] }),
    Boolean                                  $report_ja3n                 = lookup('profile::cache::haproxy::report_ja3n', { 'default_value'                 => false }),
    Boolean                                  $report_ja4h                 = lookup('profile::cache::haproxy::report_ja4h', { 'default_value'                 => false }),
    Boolean                                  $use_datacenter_provenance   = lookup('profile::cache::haproxy::use_datacenter_provenance', {'default_value'    => false }),
    Boolean                                  $use_res_proxy_provenance    = lookup('profile::cache::haproxy::use_res_proxy_provenance', {'default_value'     => false }),
    Boolean                                  $use_private_data            = lookup('profile::cache::haproxy::use_private_data', {'default_value'             => false }),
    Boolean                                  $use_etcd_known_client_ident = lookup('profile::cache::haproxy::use_etcd_known_client_ident', { 'default_value' => false }),
    Boolean                                  $media_qos                   = lookup('profile::cache::haproxy::media_qos', {'default_value'                    => false }),
    Boolean                                  $use_etcd_moat_scope         = lookup('profile::cache::haproxy::use_etcd_moat_scope', {'default_value'          => false }),
    Boolean                                  $use_cidergrinder            = lookup('profile::cache::haproxy::use_cidergrinder', {'default_value'             => false }),
    Boolean                                  $use_webrequest_ipreputation = lookup('profile::cache::haproxy::use_webrequest_ipreputation', {'default_value'  => false }),
) {
    class { 'sslcert::dhparam':
    }
    if $use_etcd_req_filters {
        $site_resource = Haproxy::Confd_site['tls']
    } else {
        $site_resource = Haproxy::Site['tls']
    }
    # variable used inside HAProxy's systemd unit
    $pid = '/run/haproxy/haproxy.pid'

    # We install HAProxy from custom component if we don't want to use
    # the one shipped in official Trixie repository
    unless debian::codename::eq('trixie') and $haproxy_version == 'haproxy30' {
        $component = "thirdparty/${haproxy_version}"
        apt::package_from_component { 'haproxy':
            component       => $component,
            before          => Class['haproxy'],
            priority        => 1002, # Take precedence over main
            ensure_packages => false, # this is handled by ::haproxy
        }
    }

    # If numa_networking is turned on, use interface_primary for NUMA hinting,
    # otherwise use 'lo' for this purpose.  Assumes NUMA data has "lo" interface
    # mapped to all cpu cores in the non-NUMA case.  The numa_iface variable is
    # in turn consumed by the systemd unit and config templates.
    if $numa_networking {
        $numa_iface = $facts['interface_primary']
    } else {
        $numa_iface = 'lo'
    }

    # used on haproxy.cfg.erb
    $socket = '/run/haproxy/haproxy.sock'
    $min_tls_version = 'TLSv1.2'
    $max_tls_version = 'TLSv1.3'
    # WARNING: if you are adding a file here, it needs to be added *before* you
    # use it in the configurations managed by confd. If you are removing a file here,
    # it needs to be removed *after* you remove its useage in the configurations managed
    # by confd. This is all to ensure no race conditions occur.
    $private_lua_files = ['main.lua']
    # files that need to be deployed but not loaded by HAProxy directly
    $private_data_files = ['browser_versions.lua']

    # used to check the list of certificates, needs to be defined before systemd service
    # template. See below for usage
    $tls_check_cfg = '/etc/haproxy-tls-check.cfg'

    $haproxy_package_name = $haproxy_version? {
        'haproxy32-awslc' => 'haproxy-awslc',
        default           => 'haproxy',
    }

    class { 'haproxy':
        package_name          => $haproxy_package_name,
        config_content        => template('profile/cache/haproxy.cfg.erb'),
        systemd_content       => template('profile/cache/haproxy.service.erb'),
        logging               => false,
        monitor_check_haproxy => false,
    }

    ensure_packages('python3-pystemd')
    file { '/usr/local/sbin/haproxy-stek-manager':
        ensure => file,
        source => 'puppet:///modules/profile/cache/haproxy_stek_manager.py',
        owner  => root,
        group  => root,
        mode   => '0544',
    }

    systemd::tmpfile { 'haproxy_secrets_tmpfile':
        content => 'd /run/haproxy-secrets 0700 haproxy haproxy -',
    }

    $tls_ticket_keys_path = '/run/haproxy-secrets/stek.keys'
    systemd::timer::job { 'haproxy_stek_job':
        ensure      => present,
        description => 'HAProxy STEK manager',
        command     => "/usr/local/sbin/haproxy-stek-manager ${tls_ticket_keys_path}",
        interval    => [
            {
                'start'    => 'OnCalendar',
                'interval' => '*-*-* 00/8:00:00', # every 8 hours
            },
            {
                'start'    => 'OnBootSec',
                'interval' => '0sec',
            },
        ],
        user        => 'root',
        require     => File['/usr/local/sbin/haproxy-stek-manager'],
    }

    $tmpfs_path = '/run/haproxy-tls'
    $volatile_tls_path = $use_tls_tmpfiles? {
        true    => $tmpfs_path,
        default => undef,
    }

    systemd::tmpfile { 'haproxy_tls_material':
        ensure  => $use_tls_tmpfiles.bool2str('present', 'absent'),
        content => "d ${volatile_tls_path} 0700 haproxy haproxy -",
    }

    $enabled_certificates.each|String $cert_name| {
        if !$available_certificates[$cert_name] {
            fail("Enabled certificate ${cert_name} isn't available")
        }
    }

    # Iterate over all available_certificate structure and check if
    # the cert_paths starts with the required prefix, depending on the usage
    # of volatile storage for tls keys or not
    $available_certificates.each |String $cert_name, Haproxy::Tlscertificate $avail_cert| {
        $avail_cert['cert_paths'].each |Stdlib::Unixpath $path| {
            if $use_tls_tmpfiles {
                unless($path.stdlib::start_with($volatile_tls_path)) {
                    fail("Certificate path ${path} should match with ${volatile_tls_path}")
                }
            } else {
                if $path =~ $tmpfs_path {
                    fail("Certificate path ${path} should NOT match with ${tmpfs_path}")
                }
            }
        }
    }

    $available_certificates.each|String $cert_name, Haproxy::Tlscertificate $cert| {
        acme_chief::cert { $cert_name:
            puppet_svc => 'haproxy',
            key_group  => 'haproxy',
            certs_path => $volatile_tls_path,
        }
    }

    # The reason we are doing filter and then map is because a map will also include nil elements for
    # each $available_certificates that's not on $enabled_certificates.
    $certificates = $available_certificates.filter |String $cert_name, Haproxy::Tlscertificate $cert| {
        $cert_name in $enabled_certificates
    }.map |String $cert_name, Haproxy::Tlscertificate $cert| {
        $cert
    }

    # Create a separate list of certificates that needs to be checked by the
    # tls-check script.
    # Not to be confused with the list that haproxy uses to load TLS certificates
    # (although they contains the same certificates paths)
    file { $tls_check_cfg:
        ensure  => file,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/cache/haproxy/tls-check.cfg.erb'),
    }

    file { '/usr/local/sbin/tls-check':
        ensure  => file,
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        content => file('profile/cache/tls-check.sh'),
    }

    ## HAProxy configuration
    # per cluster feature flags
    $feature_flags = $cache_cluster ? {
        'upload' => {
            'bwlimit'   => true,
            'jwt'       => false,
            'media_qos' => $media_qos },
        default  => {
            'bwlimit' => false,
            'jwt'     => true }
    }
    file { '/etc/haproxy/jwt':
        ensure  => bool2str($feature_flags['jwt'], 'directory', 'absent'),
        recurse => $feature_flags['jwt'],
        source  => 'puppet:///modules/profile/cache/haproxy/jwt/',
        owner   => 'haproxy',
        group   => 'haproxy',
        mode    => '0644',
        purge   => 'true',
        force   => 'true',
    }

    # Networks we trust and will bypass most filters
    if $profile::cache::base::wikimedia_trust {
        $wikimedia_trust = $profile::cache::base::wikimedia_trust
    } else {
        $wikimedia_trust = ['127.0.0.1/8', '::1']
    }
    $crt_list_path = '/etc/haproxy/crt-list.cfg'
    $hc_sources_file_path = '/etc/haproxy/allowed-hc-sources.lst'

    # Build the list of certificates to be used in the tls terminator
    $ecdhe_curves = ['X25519', 'P-256']
    $alpn = ['h2', 'http/1.1']
    file { $crt_list_path:
        mode    => '0444',
        content => template('profile/cache/haproxy/crt-list.cfg.erb'),
        notify  => Service['haproxy'],
    }

    mediawiki::errorpage { '/etc/haproxy/tls-terminator-tls-plaintext-error.html':
        ensure  => ($http_redirection_port != undef).bool2str('present', 'absent'),
        content => '<p>Insecure request forbidden, use HTTPS instead. For details see <a href="https://lists.wikimedia.org/hyperkitty/list/mediawiki-api-announce@lists.wikimedia.org/message/VKQJRS36NXLIMHOWBOXJPUH35KETQCG5/">https://lists.wikimedia.org/hyperkitty/list/mediawiki-api-announce@lists.wikimedia.org/message/VKQJRS36NXLIMHOWBOXJPUH35KETQCG5/</a>.</p>',
        before  => $site_resource,
    }

    # This contains the PyBal IPs allowed to perform healthchecks
    file { $hc_sources_file_path:
        ensure  => bool2str($dedicated_hc_backend, 'file','absent'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/cache/haproxy/allowed-hc-sources.lst.erb'),
        notify  => Service['haproxy'],
    }

    # Regexes used to validate the host header
    file { '/etc/haproxy/allowed-hosts.map':
        ensure => file,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/cache/allowed-hosts.map',
        notify => Service['haproxy'],
    }

    $http_reuse = 'always'
    # The haproxy site configuration
    file { '/etc/haproxy/ipblocks.d/':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/haproxy/ip-reputation.d/':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/usr/local/bin/check-haproxy-map':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/cache/check-haproxy-map.sh',
    }

    file { '/etc/haproxy/lua/private/':
        ensure  => $use_private_data.bool2str('directory', 'absent'),
        owner   => 'haproxy',
        group   => 'haproxy',
        recurse => true,
        purge   => true,
    }

    # lint:ignore:puppet_url_without_modules
    if $use_private_data {
        $private_lua_files.each |String[1] $lua_file_name| {
            file { "/etc/haproxy/lua/private/${lua_file_name}":
                ensure  => present,
                source  => "puppet:///volatile/private_cdn/CDN/haproxy_lua/${lua_file_name}",
                require => File['/etc/haproxy/lua/private'],
                owner   => 'haproxy',
                group   => 'haproxy',
                mode    => '0644',
                notify  => Service['haproxy'],
                before  => Service['haproxy'],
            }
        }

        $private_data_files.each |String[1] $data_file_name| {
            file { "/etc/haproxy/lua/private/${data_file_name}":
                ensure  => present,
                source  => "puppet:///volatile/private_cdn/CDN/haproxy_lua/${data_file_name}",
                require => File['/etc/haproxy/lua/private'],
                owner   => 'haproxy',
                group   => 'haproxy',
                mode    => '0644',
                notify  => Service['haproxy'],
                before  => Service['haproxy'],
            }
        }
    }
    # lint:endignore

    if $use_etcd_req_filters {
        # Haproxy ipblock map generated fully in confd directly from the ipblocks contents in etcd.
        confd::file { '/etc/haproxy/ipblocks.d/all.map':
            ensure     => present,
            prefix     => $conftool_prefix,
            watch_keys => ['/request-ipblocks'],
            content    => template('profile/cache/haproxy/ipblocks-all.map.tpl.erb'),
            # Please, whoever sees this in the future, don't @ me about this.
            # An haproxy map file can contain either blank lines, comments,
            # or lines with key-value pairs separated by spaces.
            # The check command is a perl one-liner that checks for these three cases.
            # If you find a nicer solution that doesn't involve writing a custom
            # parser, please fix this.
            check      => '/usr/local/bin/check-haproxy-map',
            reload     => '/usr/bin/systemctl reload haproxy.service',
            before     => Service['haproxy'],
        }
        # Map file of ipblocks as computed via hiddenparma.
        confd::file { '/etc/haproxy/ipblocks.d/hiddenparma.map':
            ensure     => present,
            prefix     => $conftool_prefix,
            watch_keys => ['/request-haproxy-provenance-map', '/active-scopes'],
            content    => template('profile/cache/haproxy/ipblocks-hiddenparma.map.tpl.erb'),
            check      => '/usr/local/bin/check-haproxy-map',
            reload     => '/usr/bin/systemctl reload haproxy.service',
            before     => Service['haproxy'],
        }
        # Here we configure different request scopes and the condition needed to apply them.
        # Please note: conditions will be checked in the sequence they are in the array below and
        # the scope of the *first* matching condition is the one that will be used.
        $requestctl_scopes = [
            ['moat', 'always_false'], # This is the moat-mode scope, which is never included in the requestctl backend definitions.
            ['default', '!is_trusted_request !is_identified_bot_request !is_auth_request'], # This is the default scope, it should typically be at the bottom of the list.
        ]

        if $use_etcd_known_client_ident {
            $tls_terminator_watch_keys = ['/request-haproxy-dsl/', '/request-haproxy-known-client-dsl/']
        } else {
            $tls_terminator_watch_keys = ['/request-haproxy-dsl/']
        }
        haproxy::confd_site { 'tls':
            ensure     => present,
            prefix     => $conftool_prefix,
            watch_keys => $tls_terminator_watch_keys,
            content    => template('profile/cache/haproxy/tls_terminator.cfg.erb'),
        }
    } else {
        # deployment-prep still uses static configuration of abusers
        $abuse_networks = network::parse_abuse_nets('varnish')
        file { '/etc/haproxy/ipblocks.d/all.map':
            ensure       => file,
            content      => template('profile/cache/haproxy/ipblocks-all.map.erb'),
            validate_cmd => '/usr/local/bin/check-haproxy-map %',
        }

        haproxy::site { 'tls':
            ensure  => present,
            content => template('profile/cache/haproxy/tls_terminator.cfg.erb'),
        }
    }

    haproxy::site { 'redirection_port':
        ensure  => present,
        content => template('profile/cache/haproxy/redirection_port.cfg.erb'),
    }

    if $monitoring_enabled {
        profile::cache::haproxy::monitoring { 'haproxy_tls_monitoring':
            port         => $tls_port,
            certificates => $certificates,
            require      => $site_resource,
        }
    }

    systemd::service { 'haproxy-mtail@tls.socket':
        content => systemd_template('haproxy-mtail@.socket'),
    }

    systemd::service { 'haproxy-mtail@tls':
        content => systemd_template('haproxy-mtail@'),
    }

    rsyslog::conf { 'haproxy@tls':
        priority => 20,
        content  => template('profile/cache/haproxy.rsyslog.conf.erb'),
    }

    mtail::program { 'cache_haproxy':
        source      => 'puppet:///modules/mtail/programs/cache_haproxy.mtail',
        destination => $mtail_dir,
        notify      => Service['haproxy-mtail@tls'],
    }

    file { '/usr/local/sbin/haproxy-restart':
        ensure  => file,
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        content => file('profile/cache/haproxy_restart.sh'),
    }

    ###########
    # Benthos #
    ###########
    if $use_benthos {
        include profile::benthos
    }

    #####################
    # LUA scripting     #
    #####################
    # Base directory for all LUA scripts
    file { '/etc/haproxy/lua':
        ensure  => directory,
        owner   => 'haproxy',
        group   => 'haproxy',
        mode    => '0755',
        require => File['/etc/haproxy'],
    }

    #####################
    # maxmind db lookup #
    #####################

    $lua_version = $haproxy_version? {
        'haproxy30'       => '5.4',
        'haproxy32'       => '5.4',
        'haproxy32-awslc' => '5.4',
        default           => '5.3'
    }

    package { "lua${lua_version}-maxminddb":
        ensure => present,
    }

    # lint:ignore:puppet_url_without_modules
    if ($use_datacenter_provenance or $use_res_proxy_provenance) {
        file { '/usr/share/GeoIP/datacenter.mmdb':
            ensure  => present,
            source  => 'puppet:///volatile/datacenter_vendors/datacenter.mmdb',
            require => File['/usr/share/GeoIP']
        }

        file { '/usr/share/GeoIP/proxy.mmdb':
            ensure  => present,
            source  => 'puppet:///volatile/ip_reputation_vendors/proxy.mmdb',
            require => File['/usr/share/GeoIP']
        }
    }
    if ($use_cidergrinder) {
        file { '/usr/share/CIDERGRINDER':
            ensure  => directory,
            source  => 'puppet:///volatile/CIDERGRINDER',
            recurse => true,
            notify  => Service['haproxy'],
            before  => Service['haproxy'],
        }
    }
    # lint:endignore

    file { '/etc/haproxy/lua/maxmind-lookup.lua':
        ensure  => file,
        mode    => '0644',
        owner   => 'haproxy',
        group   => 'haproxy',
        content => file('profile/cache/maxmind-lookup.lua'),
        require => [File['/etc/haproxy/lua'], Package["lua${lua_version}-maxminddb"]],
        notify  => Service['haproxy'],
        before  => Service['haproxy'],
    }

    # lint:ignore:puppet_url_without_modules
    if $use_private_data {
      ['top_10000_ips_requestctl_webrequest_text_7days', 'top_10000_ips_requestctl_webrequest_upload_7days'].each |String $top_10000_ips_requestctl_webrequest| {
          file { "/etc/haproxy/ip-reputation.d/${top_10000_ips_requestctl_webrequest}.map":
              ensure  => ($use_webrequest_ipreputation).bool2str('file', 'absent'),
              mode    => '0644',
              owner   => 'haproxy',
              group   => 'haproxy',
              source  => "puppet:///volatile/webrequest_dump/${top_10000_ips_requestctl_webrequest}.txt",
              require => File['/etc/haproxy/ip-reputation.d'],
              notify  => Service['haproxy'],
              before  => [Service['haproxy'], $site_resource],
          }
      }
    }
    # lint:endignore

    file { '/etc/haproxy/lua/ja3n.lua':
        ensure  => $report_ja3n.bool2str('file', 'absent'),
        mode    => '0644',
        owner   => 'haproxy',
        group   => 'haproxy',
        content => file('profile/cache/ja3n.lua'),
        require => File['/etc/haproxy/lua'],
        notify  => Service['haproxy'],
        before  => Service['haproxy'],
    }

    file { '/etc/haproxy/lua/ja4h.lua':
        ensure  => $report_ja4h.bool2str('file', 'absent'),
        mode    => '0644',
        owner   => 'haproxy',
        group   => 'haproxy',
        content => file('profile/cache/ja4h.lua'),
        require => File['/etc/haproxy/lua'],
        notify  => Service['haproxy'],
        before  => Service['haproxy'],
    }

    file { '/etc/haproxy/lua/utf8ps.lua':
        ensure  => 'present',
        mode    => '0644',
        owner   => 'haproxy',
        group   => 'haproxy',
        content => file('profile/cache/utf8ps.lua'),
        require => File['/etc/haproxy/lua'],
        notify  => Service['haproxy'],
        before  => Service['haproxy'],
    }

    file { '/etc/haproxy/lua/contact_info.lua':
        ensure  => 'file',
        mode    => '0644',
        owner   => 'haproxy',
        group   => 'haproxy',
        content => file('profile/cache/contact_info.lua'),
        notify  => Service['haproxy'],
        before  => Service['haproxy'],
    }

    if $use_cidergrinder {
        ensure_packages("lua${lua_version}-ciderbloom")
        file { '/etc/haproxy/lua/cidergrinder_bloom.lua':
            ensure  => $use_cidergrinder.bool2str('file', 'absent'),
            mode    => '0644',
            owner   => 'haproxy',
            group   => 'haproxy',
            content => file('profile/cache/cidergrinder_bloom.lua'),
            require => [File['/etc/haproxy/lua'], Package["lua${lua_version}-ciderbloom"]],
            notify  => Service['haproxy'],
            before  => Service['haproxy'],
        }
        file { '/etc/haproxy/lua/cidergrinder_mmdb.lua':
            ensure  => $use_cidergrinder.bool2str('file', 'absent'),
            mode    => '0644',
            owner   => 'haproxy',
            group   => 'haproxy',
            content => file('profile/cache/cidergrinder_mmdb.lua'),
            require => [File['/etc/haproxy/lua'], Package["lua${lua_version}-maxminddb"]],
            notify  => Service['haproxy'],
            before  => Service['haproxy'],
        }
    }
}
