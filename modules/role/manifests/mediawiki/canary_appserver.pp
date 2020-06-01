# Class for a subgroup of appservers where we can test experimental features
class role::mediawiki::canary_appserver {
    include role::mediawiki::appserver
    include ::profile::base::firewall
    # Temporarily only on canaries for testing; all appservers Soon™️
    include prometheus::node_phpfpm_statustext  # lint:ignore:wmf_styleguide

    # include the deployment scripts because mwscript can occasionally be useful
    # here: T112174

    # on canary appservers, don't install "sql" scripts (T211512)
    class { 'scap::scripts':
        sql_scripts => absent,
    }
}
