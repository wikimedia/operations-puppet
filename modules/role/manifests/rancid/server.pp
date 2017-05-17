# Really Awful Notorious CIsco config Differ
class role::rancid::server {

    system::role { 'rancid::server':
        description => 'Really Awful Notorious CIsco config Differ (sp)'
    }

    include ::rancid
    include ::profile::backup::host

    backup::set { 'rancid': }
}
