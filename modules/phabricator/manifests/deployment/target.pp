# == Class phabricator::deployment::target
# This sets up sudo rules and the deploy_user for phabricator deployments with
# scap3.

class phabricator::deployment::target(
  $deploy_user,
  $deploy_key,
  $deploy_target= 'phabricator/deployment',
) {
    scap::target { $deploy_target:
        deploy_user => $deploy_user,
        sudo_rules  => [
            'ALL=(root) NOPASSWD: /usr/sbin/service phd *',
            'ALL=(root) NOPASSWD: /usr/sbin/service apache2 *',
        ]
    }
}
