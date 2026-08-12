# SPDX-License-Identifier: Apache-2.0
# @summary set up the puppetserver volatile direcotry
#   this directory is sed to serv
#   * external_clouds_vendors
#   * Geoip files
#   * tftp images used for the debian installer
# @param http_proxy the htp proxy url to use
# @param geoip_fetch_private Fetch the proprietary paid-for MaxMind database
# @param ip_reputation_config The configuration of the ip reputation download script
# @param ip_reputation_proxies The list of proxy families to use in the ip reputation script
# @param root_token The root token used by the requestctl cli
# @param cidergrinder_ensure ensure parameter for the cidergrinder package and timer
class profile::puppetserver::volatile (
    Optional[Stdlib::HTTPUrl] $http_proxy            = lookup('http_proxy'),
    Boolean                   $geoip_fetch_private   = lookup('profile::puppetserver::volatile::geoip_fetch_private'),
    # Should be defined in the private repo.
    Hash[String, Any]         $ip_reputation_config  = lookup('profile::puppetserver::volatile::ip_reputation_config'),
    Array[String]             $ip_reputation_proxies = lookup('profile::puppetserver::volatile::ip_reputation_proxies'),
    String                    $root_token            = lookup('profile::conftool::hiddenparma::root_token'),
    Optional[String[1]]       $cdn_private_git_token = lookup('profile::puppetserver::volatile::cdn_private_git_token', { 'default_value' => undef }),
    Wmflib::Ensure            $cidergrinder_ensure   = lookup('profile::puppetserver::volatile::cidergrinder_ensure', { 'default_value' => 'absent' }),
) {
    include profile::puppetserver
    unless $profile::puppetserver::extra_mounts.has_key('volatile') {
        fail("Must define a volatile entry in profile::puppetserver::extra_mounts to use ${title}")
    }
    include profile::puppetserver::git
    unless $profile::puppetserver::git::repos.has_key('private') {
        fail("Must define a private entry in profile::puppetserver::git::repos to use ${title}")
    }
    $private_repo_path = "${profile::puppetserver::git::basedir}/private"
    $base_path            = $profile::puppetserver::extra_mounts['volatile']
    $geoip_destdir        = "${base_path}/GeoIP"
    $geoip_destdir_ipinfo = "${base_path}/GeoIPInfo"

    # Files in this folder are managed manually
    file { "${base_path}/tftpboot":
        ensure => directory,
    }

    file { '/usr/local/sbin/update-netboot-image':
        ensure => file,
        source => 'puppet:///modules/profile/puppetserver/update-netboot-image.sh',
        mode   => '0544',
    }

    # Needed by update-netboot-image
    ensure_packages('pax')

    class { 'external_clouds_vendors':
        user        => 'root',
        manage_user => false,
        outfile     => "${base_path}/external_cloud_vendors/public_clouds.json",
        conftool    => $profile::puppetserver::enable_ca,
        http_proxy  => $http_proxy,
        api_token   => $root_token,
    }
    class { 'ip_reputation_vendors':
        ensure         => stdlib::ensure(!$ip_reputation_proxies.empty()),
        user           => 'root',
        manage_user    => false,
        outfile        => "${base_path}/ip_reputation_vendors/proxies.json",
        proxy_families => $ip_reputation_proxies,
        configuration  => $ip_reputation_config,
        http_proxy     => $http_proxy,
    }

    $spur_dch_user = 'nobody'
    $spur_dch_group = 'nogroup'
    $spur_mmdb = "${base_path}/datacenter_vendors/datacenter.mmdb"

    file { $spur_mmdb.dirname():
        ensure => $geoip_fetch_private.bool2str('directory', 'absent'),
        owner  => $spur_dch_user,
        group  => $spur_dch_group,
    }

    class { 'ip_reputation_vendors::spur_datacenter':
        ensure        => stdlib::ensure($geoip_fetch_private),
        user          => $spur_dch_user,
        group         => $spur_dch_group,
        outfile       => "${base_path}/datacenter_vendors/datacenter.mmdb",
        configuration => $ip_reputation_config,
        http_proxy    => $http_proxy,
    }

    class { 'ip_reputation_vendors::spur_feeds':
        ensure        => stdlib::ensure($geoip_fetch_private),
        user          => 'root',
        group         => $spur_dch_group,
        outfile       => "${base_path}/ip_reputation_vendors/proxy.mmdb",
        configuration => $ip_reputation_config,
        http_proxy    => $http_proxy,
    }

    class { 'profile::swift::fetch_rings':
        volatile_dir => $base_path,
    }
    # TODO: this should probably be handeled in the geoip classes
    file { [$geoip_destdir, $geoip_destdir_ipinfo]:
        ensure => directory,
    }

    if $geoip_fetch_private {
        include passwords::geoip
        class { 'geoip::data::maxmind':
            data_directory => $geoip_destdir,
            proxy          => $http_proxy,
            ca_server      => $profile::puppetserver::ca_server,
            user_id        => $passwords::geoip::user_id,
            license_key    => $passwords::geoip::license_key,
            product_ids    => [
                'GeoIP2-City',
                'GeoIP2-Connection-Type',
                'GeoIP2-Country',
                'GeoIP2-ISP',
            ],
        }
        # TODO: after I53708b14ed36c6ae0ca7d71df0fc704c60ab749b is merged, we can modify
        # accordingly to just include the freely available product_ids
        class { 'geoip::data::maxmind::ipinfo':
            data_directory => $geoip_destdir_ipinfo,
            proxy          => $http_proxy,
            ca_server      => $profile::puppetserver::ca_server,
            user_id        => $passwords::geoip::user_id_ipinfo,
            license_key    => $passwords::geoip::license_key_ipinfo,
            product_ids    => [
                'GeoLite2-ASN',
                'GeoLite2-Country',
                'GeoLite2-City',
            ],
        }
    } else {
        class { 'geoip::data::maxmind':
            data_directory => $geoip_destdir,
            proxy          => $http_proxy,
            product_ids    => [
                'GeoIP2-City',
                'GeoIP2-Connection-Type',
            ],
        }
    }

    if  $cdn_private_git_token {
        $cdn_private_repo = true
    } else {
        $cdn_private_repo = false
    }

    git::clone { 'repos/sre/xcheesescore':
        ensure    => $cdn_private_repo.bool2str('latest', 'absent'),
        directory => "${base_path}/private_cdn/",
        branch    => 'main',
        owner     => 'nobody',
        group     => 'nogroup',
        source    => 'gitlab',
        token     => $cdn_private_git_token
    }

    puppetserver::rsync_module { 'volatile':
        path     => $base_path,
        hosts    => wmflib::class::hosts('profile::puppetserver::volatile'),
        interval => { 'start' => 'OnUnitInactiveSec', 'interval' => '15m' },
    }

    # This system user is configured to allow the DSE k8s cluster to rsync
    # data to volatile via Airflow.
    $webrequest_dump_dir = "${base_path}/webrequest_dump"
    # The purpose of the geomap_dump dir is to hold data
    # queried from the event.development_network_probe Hive table
    # For more information, see T402512
    $geomap_dump_dir = "${base_path}/geomap_dump"
    ssh::userkey { 'analytics-sre':
        source => 'puppet:///modules/profile/puppetserver/analytics_sre_authorized_keys',
    }

    # Allow SSH from the DSE K8s cluster's pod IP range
    firewall::service { 'ssh_dse-K8s_pods':
        proto    => 'tcp',
        port     => 22,
        src_sets => ['DSE_KUBEPODS_NETWORKS'],
    }

    # The analytics-sre user will be able to write only the following 2 directories.
    file { $webrequest_dump_dir:
        ensure => directory,
        owner  => 'analytics-sre',
        group  => 'analytics-sre',
    }
    file { $geomap_dump_dir:
        ensure => directory,
        owner  => 'analytics-sre',
        group  => 'analytics-sre',
    }

    # CIDERGRINDER: installed on all puppetservers; nightly grind runs on the primary only.
    ensure_packages(['cidergrinder'], {'ensure' => $cidergrinder_ensure})

    systemd::sysuser { 'cidergrinder':
        description => 'CIDERGRINDER Spur.us dataset compressor user',
    }

    $cidergrinder_dir = "${base_path}/CIDERGRINDER"

    file { $cidergrinder_dir:
        ensure => stdlib::ensure($cidergrinder_ensure, 'directory'),
        owner  => 'cidergrinder',
        group  => 'cidergrinder',
        mode   => '0755',
    }

    if $profile::puppetserver::enable_ca {
        $spur_token = $ip_reputation_config['headers'] ? {
            undef   => undef,
            default => $ip_reputation_config['headers']['Token'],
        }
        $cidergrinder_env = $spur_token ? {
            undef   => {},
            default => { 'CIDERGRINDER_HTTP_HEADERS' => "Token: ${spur_token}" },
        }

        systemd::timer::job { 'cidergrinder_grind_anonymous_residential':
            ensure            => $cidergrinder_ensure,
            command           => '/usr/bin/CIDERGRINDER spur grind anonymous-residential.cider --bloom-factor=3 -i https://feeds.spur.us/v2/anonymous-residential/latest.json.gz',
            description       => 'Nightly cidergrinder grind for anonymous-residential feed',
            user              => 'cidergrinder',
            working_directory => $cidergrinder_dir,
            logging_enabled   => true,
            syslog_identifier => 'cidergrinder-grind',
            environment       => $cidergrinder_env + { 'https_proxy' => 'http://webproxy:8080' },
            interval          => {'start' => 'OnCalendar', 'interval' => '*-*-* 02:30:00'},
            require           => [
                Package['cidergrinder'],
                File[$cidergrinder_dir],
            ],
        }
    }

    prometheus::node_textfile { 'airflow-webrequest-top-ips-file-checker-metrics':
        ensure     => 'present',
        filesource => 'puppet:///modules/profile/puppetserver/volatile/airflow_file_checker.sh',
        interval   => 'daily',
        run_cmd    => "/usr/local/bin/airflow-webrequest-top-ips-file-checker-metrics ${webrequest_dump_dir}",
    }

}
