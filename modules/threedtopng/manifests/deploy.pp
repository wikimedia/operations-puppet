# == Class: threedtopng::deploy
#
# Deploy 3d2png via scap
#
class threedtopng::deploy (
) {
    ensure_packages(['nodejs', 'nodejs-legacy', 'xvfb', 'xauth', 'libgl1-mesa-dri'])

    # On Thumbor servers the mwdeploy user and group are not present by default
    scap::target { '3d2png/deploy':
        deploy_user => 'mwdeploy',
        manage_user => true,
    }
}
