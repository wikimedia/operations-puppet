# === Class role::deployment::mediawiki
# Installs everything needed to deploy mediawiki
class role::deployment::mediawiki(
    $keyholder_user = 'mwdeploy',
    $keyholder_group = ['wikidev', 'mwdeploy'],
) {

    # All needed classes for deploying mediawiki
    include ::mediawiki

    # On jessie our app servers were running on HHVM and they only install minimal
    # PHP packages (just php5-cli). On the deployment servers however we need the
    # full set of packages defined by mediawiki::packages::php5. On stretch we don't
    # need that since we're installing the full set of PHP packages universally
    if os_version('debian' == 'jessie') {
        include ::mediawiki::packages::php5
    }

    include ::profile::mediawiki::nutcracker
    include ::profile::conftool::client
    include ::scap::master
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
