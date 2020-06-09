# @summary a class to install the jumpcloud scraping script and create the correct exim files
# @param api_uri the jumpcloud api uri endpoint
# @param api_key The jumpcloud API key
# @param managed_domain The domain name of the jumpcloud managed domain
# @param aliases_dir location of aliases directory
class profile::mail::jumpcloud (
) {
    file{ ['/usr/local/sbin/jumpcloud_aliases',
            '/etc/jumpcloud.ini']:
        ensure => absent,
    }
    systemd::timer::job {'generate jumpcloud aliases':
        ensure => absent,
    }
}
