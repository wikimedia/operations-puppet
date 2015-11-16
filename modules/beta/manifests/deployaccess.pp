# TODO: remove this if https://phabricator.wikimedia.org/T121721
# is fixed.
class beta::deployaccess(
    $bastion_ip = '10.68.16.58', # ip of deployment-bastion
) {

    security::access::config { 'beta-allow-mwdeploy':
        content  => "+ : deploy-service mwdeploy : ${bastion_ip}\n",
        priority => 50,
    }

    # Allow eventlogging user to deploy.
    security::access::config { 'beta-allow-eventlogging':
        content  => "+ : eventlogging : ${bastion_ip}\n",
        priority => 51,
    }

}
