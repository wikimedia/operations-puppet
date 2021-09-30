# Class: profile::url_downloader
#
class profile::url_downloader (
    Stdlib::Port $url_downloader_port = lookup('profile::url_downloader::url_downloader_port'),
) {

    include network::constants

    # TODO rework all this ugly mess
    if $::realm == 'production' {
        $wikimedia = flatten([
            $network::constants::all_network_subnets['production']['eqiad']['public']['public1-a-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['public']['public1-a-eqiad']['ipv6'],
            $network::constants::all_network_subnets['production']['eqiad']['public']['public1-b-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['public']['public1-b-eqiad']['ipv6'],
            $network::constants::all_network_subnets['production']['eqiad']['public']['public1-c-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['public']['public1-c-eqiad']['ipv6'],
            $network::constants::all_network_subnets['production']['eqiad']['public']['public1-d-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['public']['public1-d-eqiad']['ipv6'],

            $network::constants::all_network_subnets['production']['codfw']['public']['public1-a-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['codfw']['public']['public1-a-codfw']['ipv6'],
            $network::constants::all_network_subnets['production']['codfw']['public']['public1-b-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['codfw']['public']['public1-b-codfw']['ipv6'],
            $network::constants::all_network_subnets['production']['codfw']['public']['public1-c-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['codfw']['public']['public1-c-codfw']['ipv6'],
            $network::constants::all_network_subnets['production']['codfw']['public']['public1-d-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['codfw']['public']['public1-d-codfw']['ipv6'],

            $network::constants::all_network_subnets['production']['eqiad']['private']['private1-a-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['private']['private1-a-eqiad']['ipv6'],
            $network::constants::all_network_subnets['production']['eqiad']['private']['private1-b-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['private']['private1-b-eqiad']['ipv6'],
            $network::constants::all_network_subnets['production']['eqiad']['private']['private1-c-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['private']['private1-c-eqiad']['ipv6'],
            $network::constants::all_network_subnets['production']['eqiad']['private']['private1-d-eqiad']['ipv4'],
            $network::constants::all_network_subnets['production']['eqiad']['private']['private1-d-eqiad']['ipv6'],

            $network::constants::all_network_subnets['production']['codfw']['private']['private1-a-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['codfw']['private']['private1-a-codfw']['ipv6'],
            $network::constants::all_network_subnets['production']['codfw']['private']['private1-b-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['codfw']['private']['private1-b-codfw']['ipv6'],
            $network::constants::all_network_subnets['production']['codfw']['private']['private1-c-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['codfw']['private']['private1-c-codfw']['ipv6'],
            $network::constants::all_network_subnets['production']['codfw']['private']['private1-d-codfw']['ipv4'],
            $network::constants::all_network_subnets['production']['codfw']['private']['private1-d-codfw']['ipv6'],

            # Kubernetes services/main cluster pods
            $network::constants::services_kubepods_networks,
            # Kubernetes staging cluster pods
            $network::constants::staging_kubepods_networks,

            $network::constants::all_network_subnets['production']['esams']['public']['public1-esams']['ipv4'], #TODO: Do we need this ?
            $network::constants::all_network_subnets['production']['esams']['public']['public1-esams']['ipv6'], #TODO: Do we need this ?

            ])
    } elsif $::realm == 'labs' {
        $wikimedia = [
            $network::constants::all_network_subnets['labs']['eqiad']['private']['cloud-instances2-b-eqiad']['ipv4'],
        ]
    } else {
        fail('Dont use this role outside of wikimedia')
    }
    $towikimedia = $wikimedia

    $config_content = template('profile/url_downloader/squid.conf.erb')

    class { 'squid':
        config_content => $config_content,
    }

    ferm::service { 'url_downloader':
        proto  => 'tcp',
        port   => $url_downloader_port,
        srange => '$DOMAIN_NETWORKS',
    }

    monitoring::service { 'url_downloader':
        description   => 'url_downloader',
        check_command => "check_tcp_ip!url-downloader.wikimedia.org!${url_downloader_port}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Url-downloader',
    }

    base::service_auto_restart { 'squid': }
}
