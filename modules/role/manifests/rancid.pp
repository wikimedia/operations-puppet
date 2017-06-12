# Really Awful Notorious CIsco config Differ
class role::rancid {

    system::role { 'rancid':
        description => 'Really Awful Notorious CIsco config Differ (sp)'
    }

    include ::standard
    include ::rancid
    include ::profile::backup::host

    backup::set { 'rancid': }
}
