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

class profile::puppetserver::volatile (
    Optional[Stdlib::HTTPUrl] $http_proxy            = lookup('http_proxy'),
    Boolean                   $geoip_fetch_private   = lookup('profile::puppetserver::volatile::geoip_fetch_private'),
    # Should be defined in the private repo.
    Hash[String, Any]         $ip_reputation_config  = lookup('profile::puppetserver::volatile::ip_reputation_config'),
    Array[String]             $ip_reputation_proxies = lookup('profile::puppetserver::volatile::ip_reputation_proxies'),
){
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
        ensure => present,
        source => 'puppet:///modules/profile/puppetserver/update-netboot-image.sh',
        mode   => '0544',
    }

    # Needed by update-netboot-image
    ensure_packages('pax')

    class { 'external_clouds_vendors':
        user         => 'root',
        manage_user  => false,
        outfile      => "${base_path}/external_cloud_vendors/public_clouds.json",
        conftool     => $profile::puppetserver::enable_ca,
        http_proxy   => $http_proxy,
        private_repo => $private_repo_path,
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

    puppetserver::rsync_module { 'volatile':
        path     => $base_path,
        hosts    => wmflib::class::hosts('profile::puppetserver::volatile'),
        interval => {'start' => 'OnUnitInactiveSec', 'interval' => '15m'},
    }
}
