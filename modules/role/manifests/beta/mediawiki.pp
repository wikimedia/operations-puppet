# == Class role::beta::mediawiki
#
# Allow mwdeploy to login from scap deployment host. Adds an exception in
# /etc/security/access.conf to work around labs-specific restrictions
#
# filtertags: labs-project-deployment-prep
class role::beta::mediawiki {
    include ::base::firewall

    $ips = join($network::constants::special_hosts[$::realm]['deployment_hosts'], ' ')
    security::access::config { 'scap-allow-mwdeploy':
        content  => "+ : mwdeploy : ${ips}\n",
        priority => 60,
    }
}
