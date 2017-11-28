# Class for a subgroup of appservers where we can test experimental features
class role::mediawiki::canary_appserver {
    include role::mediawiki::appserver

    # include the deployment scripts because mwscript can occasionally be useful
    # here: T112174
    include scap::scripts
}

