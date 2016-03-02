# == Class phabricator::deployment::source
# Include this class on a scap3 deployment server (e.g. tin, deployment-bastion)
# to configure the keyholder agent.
#
# This sets up private keys and adds them to keyholder, allowing members of the
# trusted_group to deploy via ssh using the configured ssh key for the
# deploy user.
#
# TODO: I'd like to move this information to hiera so that we can consolodate
# the keyholder configuration in one place instead of scattering it around in
# service::deployment::source classes.

class phabricator::deployment::source(
  $key_fingerprint      = '39:b3:2c:a7:b2:80:65:ff:0c:97:e1:22:88:6c:59:10',
  $trusted_group        = 'phabricator-roots'
) {
    require ::keyholder
    require ::keyholder::monitoring

    keyholder::agent { 'phabricator':
        trusted_group   => $trusted_group,
        key_fingerprint => $key_fingerprint,
        key_content     => secret('phabricator/phab_deploy_private_key'),
    }
}
