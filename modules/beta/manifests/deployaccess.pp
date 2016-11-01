# TODO: remove this if https://phabricator.wikimedia.org/T121721
# is fixed.
class beta::deployaccess {
    $ips = join($network::constants::special_hosts[$::realm]['deployment_hosts'], ' ')
    security::access::config { 'beta-allow-mwdeploy':
        content  => "+ : deploy-service mwdeploy : ${ips}\n",
        priority => 50,
    }
}
