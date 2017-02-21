# sets upt APT repository for labs openstack.
#  We use the Ubuntu cloud archive for this -- this repo points us to the
#  package versions specified in $::openstack::version
class openstack::repo(
    $openstack_version=$::openstack::version,
) {
    # As of 26/10/2015 we support kilo on trusty (lsb_release -c)
    if ($::lsbdistcodename == 'trusty') {
        apt::repository { 'ubuntucloud':
            uri        => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
            dist       => "trusty-updates/${openstack_version}",
            components => 'main',
            keyfile    => 'puppet:///modules/openstack/ubuntu-cloud.key';
        }
    } elsif os_version('debian jessie') {
        apt::conf { 'mirantis-jessie-proxy':
            priority => '80',
            key      => "Acquire::http::Proxy::${openstack_version}-jessie.pkgs.mirantis.com",
            value    => "http://webproxy.${::site}.wmnet:8080",
        }
        apt::repository { 'mirantis':
            uri        => "http://${openstack_version}-jessie.pkgs.mirantis.com/debian",
            dist       => "jessie-${openstack_version}-backports",
            components => 'main',
            keyfile    => "puppet:///modules/openstack/mirantis-${openstack_version}.key";
        }
        apt::repository { 'mirantis-nochange':
            uri        => "http://${openstack_version}-jessie.pkgs.mirantis.com/debian",
            dist       => "jessie-${openstack_version}-backports-nochange",
            components => 'main',
            keyfile    => "puppet:///modules/openstack/mirantis-${openstack_version}.key";
        }
    }
}
