# === Class role::deployment::mediawiki
# Installs everything needed to deploy mediawiki
class role::deployment::mediawiki(
    $keyholder_user = 'mwdeploy',
    $keyholder_group = ['wikidev', 'mwdeploy'],
) {

    # All needed classes for deploying mediawiki
    include ::mediawiki
    include ::mediawiki::packages::php5
    include ::profile::mediawiki::nutcracker
    include ::profile::conftool::client
    include ::scap::master
    include ::profile::scap::dsh
    include ::scap::ferm

    # mcrouter testing (T151466)
    if $::realm == 'labs' {
        include ::profile::mediawiki::mcrouter_wancache
    }

    # Keyholder
    require ::keyholder
    require ::keyholder::monitoring

    keyholder::agent { $keyholder_user:
        trusted_groups  => $keyholder_group,
    }

    # Wikitech credentials file
}
