# Class: role::url_downloader
#
# A role class for assigning the url_downloader role to a host. The host needs
# to have the $url_downloader_ip variable set at hiera otherwise it defaults to
# $::ipaddress
#
# Parameters:
#
# Actions:
#       Use the url_downloader module class to configure a squid service
#       Setup firewall rules
#       Setup monitoring rules
#       Pin our packages
#
# Requires:
#       Module url_downloader
#       ferm
#       nagios definitions for wmf
#
# Sample Usage:
#       node /test.wikimedia.org/ {
#           role url_downloader
#       }
class role::url_downloader {
    system::role { 'url_downloader':
        description => 'Upload-by-URL proxy'
    }
    include network::constants

    $url_downloader_ip = hiera('url_downloader_ip', $::ipaddress)

    if $::realm == 'production' {
        $wikimedia = [
            # TODO: Add IPv6 as well
            $network::constants::all_network_subnets['production']['eqiad']['public']['public1-a-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['public']['public1-b-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['public']['public1-c-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['public']['public1-d-eqiad']['ipv4'],

            $network::constants::all_network_subnets['production']['codfw']['public']['public1-a-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['codfw']['public']['public1-b-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['codfw']['public']['public1-c-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['codfw']['public']['public1-d-codfw']['ipv4'],

            $network::constants::all_network_subnets['production']['eqiad']['private']['private1-a-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['private']['private1-b-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['private']['private1-c-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['private']['private1-d-eqiad']['ipv4'],

            $network::constants::all_network_subnets['production']['codfw']['private']['private1-a-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['codfw']['private']['private1-b-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['codfw']['private']['private1-c-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['codfw']['private']['private1-d-codfw']['ipv4'],

            $network::constants::all_network_subnets['production']['codfw']['public']['public1-lvs-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['public']['public1-lvs-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['ulsfo']['public']['public1-lvs-ulsfo']['ipv4'],
            $network::constants::all_network_subnets['production']['esams']['public']['public1-lvs-esams']['ipv4'],

            $network::constants::all_network_subnets['production']['esams']['public']['public1-esams']['ipv4'], #TODO: Do we need this ?
            ]
    } elsif $::realm == 'labs' {
        $wikimedia = [
            $network::constants::all_network_subnets['production']['eqiad']['private']['labs-instances1-a-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['private']['labs-instances1-b-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['private']['labs-instances1-c-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['private']['labs-instances1-d-eqiad']['ipv4'],
        ]
    } else {
        fail('Dont use this role outside of wikimedia')
    }
    $towikimedia = $wikimedia

    # TODO: Evaluate if jessie's squid is fine with those rules
    if os_version('ubuntu >= trusty') or os_version('debian >= jessie') {
        $config_content = template('url_downloader/squid.conf.erb')
    } else {
        $config_content = template('url_downloader/precise_acls_conf.erb', 'url_downloader/squid.conf.erb')
    }

    class { 'squid3':
        config_content => $config_content,
    }

    # Restrict the service to WMF only networks using the $ALL_NETWORKS ferm
    # macro
    ferm::service { 'url_downloader':
        proto  => 'tcp',
        port   => '8080',
        srange => '$ALL_NETWORKS',
    }

    # Monitoring
    monitoring::service { 'url_downloader':
        description   => 'url_downloader',
        check_command => 'check_tcp_ip!url-downloader.wikimedia.org!8080',
    }
}
