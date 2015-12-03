class beta::deployaccess(
    $bastion_ip = '10.68.16.58', # ip of deployment-bastion
) {

    security::access { 'beta-allow-mwdeploy':
        content  => "+ : deploy-service mwdeploy : ${bastion_ip}\n",
        priority => 50,
    }

}
