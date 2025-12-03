# SPDX-License-Identifier: Apache-2.0
# @summary Cloud VPS metadata web server
class profile::wmcs::cloudvps_meta (
    Stdlib::Fqdn $host = lookup('profile::wmcs::cloudvps_meta::host', {default_value => 'meta.wmcloud.org'}),
) {
    $base_path = "/srv/${host}"

    file { $base_path:
        ensure  => directory,
        owner   => 'root',
        group   => 'www-data',
        recurse => true,
        purge   => true,
        force   => true,
    }

    class { 'httpd': }

    httpd::site { $host:
        content => template('profile/wmcs/cloudvps_meta/apache.conf.erb'),
    }

    include network::constants
    $cloudvps_ip_ranges = $network::constants::all_cloud_instance_networks + $network::constants::all_cloud_floating_networks
    # For external users, publish a version without the 172.16.0.0/12 private space included
    # (That IP space is still visible to some Wikimedia infrastructure, which is why we publish both.)
    # TODO: also exclude stuff in 2a02:ec80:aX00:100::/56 (the private v6 space supernets)?
    $public_cloudvps_ip_ranges = $cloudvps_ip_ranges.filter |$net| {
        $net !~ Stdlib::IP::Address::V4::CIDR or !stdlib::ip_in_range(wmflib::cidr_first_address($net), '172.16.0.0/12')
    }

    file { "${base_path}/cloudvps-ips-all.json":
        ensure  => file,
        content => wmflib::googlebot_ranges_json($cloudvps_ip_ranges).to_json(),
    }
    file { "${base_path}/cloudvps-ips-public.json":
        ensure  => file,
        content => wmflib::googlebot_ranges_json($public_cloudvps_ip_ranges).to_json(),
    }
}
