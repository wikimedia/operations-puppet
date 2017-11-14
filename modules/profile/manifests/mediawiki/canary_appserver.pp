class profile::mediawiki::canary_appserver {
    # include the deployment scripts because mwscript can occasionally be useful
    # here: T112174
    include scap::scripts

    # maintenance/ dump scripts still run php5 often, so allow testing that,
    # similar to the deployment hosts.
    include ::mediawiki::packages::php5
}
