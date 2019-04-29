# Really Awful Notorious CIsco config Differ
class role::rancid {

    system::role { 'rancid':
        description => 'Really Awful Notorious CIsco config Differ (sp)'
    }

    include ::profile::standard
    include ::profile::backup::host
    # include ::profile::base::firewall
    include ::profile::rancid
}
