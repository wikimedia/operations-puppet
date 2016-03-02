class phabricator::deployment::target(
  $deploy_user,
  $deploy_key,
  $deploy_target= 'phabricator/deployment',
) {
    scap::target { $deploy_target:
        deploy_user       => $deploy_user,
        public_key_source => $deploy_key,
        sudo_rules  => [
            "ALL=(root) NOPASSWD: /usr/sbin/service phd *",
            "ALL=(root) NOPASSWD: /usr/sbin/service apache2 *",
        ]
    }
}
