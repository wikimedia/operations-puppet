# == Class role::beta::mediawiki
#
# Allow mwdeploy to login from scap deployment host. Adds an exception in
# /etc/security/access.conf to work around labs-specific restrictions
class role::beta::mediawiki {
    include base::firewall

    $deployment_host = hiera('scap::deployment_server')
    $deployment_ip = ipresolve($deployment_host, 4, $::nameservers[0])
    security::access::config { 'scap-allow-mwdeploy':
        content  => "+ : mwdeploy : ${deployment_ip}\n",
        priority => 60,
    }
}
