# vim: set ts=4 et sw=4:
#
# filtertags: labs-project-deployment-prep

class profile::cxserver(
    $apertium_uri=hiera('profile::cxserver::apertium_uri'),
    $ratelimit_hosts=hiera('profile::cxserver::ratelimit_hosts'),
    $ratelimit_port=hiera('profile::cxserver::ratelimit_port'),
) {
    include ::passwords::cxserver

    $lingocloud_api_key = $::passwords::cxserver::lingocloud_api_key
    $matxin_api_key     = $::passwords::cxserver::matxin_api_key
    $google_api_key     = $::passwords::cxserver::google_api_key
    $yandex_api_key     = $::passwords::cxserver::yandex_api_key
    $youdao_app_key     = $::passwords::cxserver::youdao_app_key
    $youdao_app_secret  = $::passwords::cxserver::youdao_app_secret
    $jwt_secret         = $::passwords::cxserver::jwt_secret

    # Kick out our own IP and fqdn from the list
    $rl_hosts = $ratelimit_hosts.filter |$x| { $x != $::fqdn and $x != $::ipaddress }

    service::node { 'cxserver':
        port              => 8080,
        healthcheck_url   => '',
        has_spec          => true,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            jwt_token          => $jwt_secret,
            apertium_uri       => $apertium_uri,
            lingocloud_key     => $lingocloud_api_key,
            lingocloud_account => 'wikimedia',
            matxin_key         => $matxin_api_key,
            google_key         => $google_api_key,
            yandex_key         => $yandex_api_key,
            youdao_app_key     => $youdao_app_key,
            youdao_app_secret  => $youdao_app_secret,
            ratelimit_port     => $ratelimit_port,
            ratelimit_hosts    => $rl_hosts,
            ipaddress          => $::ipaddress,
        },
    }

    # cxserver rate limiting rule
    $cx_hosts_ferm = join($ratelimit_hosts, ' ')
    ferm::service { 'cxserver-ratelimit':
        desc   => "kademlia cxserver ratelimiting - ${ratelimit_port}",
        proto  => 'udp',
        port   => $ratelimit_port,
        srange => "@resolve((${cx_hosts_ferm}))",
    }
}
