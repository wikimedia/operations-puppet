# == Class profile::beta::mediawiki
#
# Allow mwdeploy and scap to login from scap deployment host. Adds an
# exception in /etc/security/access.conf to work around labs-specific
# restrictions
#
class profile::beta::mediawiki (
    Array[Stdlib::Host] $deployment_hosts = lookup('deployment_hosts', {'default_value' => []})
) {
    $ips = join($deployment_hosts, ' ')
    security::access::config { 'scap-allow-mwdeploy':
        content  => "+ : mwdeploy : ${ips}\n",
        priority => 60,
    }
    security::access::config { 'scap-allow-scap':
        content  => "+ : scap : ${ips}\n",
        priority => 65,
    }
}
