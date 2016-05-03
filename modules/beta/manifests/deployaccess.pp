# TODO: remove this if https://phabricator.wikimedia.org/T121721
# is fixed.
class beta::deployaccess(
    $bastion_ip = '10.68.17.240', # ip of deployment-tin
) {

    security::access::config { 'beta-allow-mwdeploy':
        content  => "+ : deploy-service mwdeploy : ${bastion_ip}\n",
        priority => 50,
    }

}
