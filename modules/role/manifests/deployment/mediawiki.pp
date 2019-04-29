# === Class role::deployment::mediawiki
# Installs everything needed to deploy mediawiki
class role::deployment::mediawiki(
    $keyholder_user = 'mwdeploy',
    $keyholder_group = ['wikidev', 'mwdeploy'],
) {
    include ::profile::mediawiki::nutcracker
    include ::profile::conftool::client
    include ::profile::deployment::mediawiki
    include ::profile::scap::dsh
    include ::scap::ferm

    # Keyholder
    require ::keyholder
    require ::keyholder::monitoring

    keyholder::agent { $keyholder_user:
        trusted_groups  => $keyholder_group,
    }

    # Wikitech credentials file
}
