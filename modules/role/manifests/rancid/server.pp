# Really Awful Notorious CIsco config Differ
class role::rancid::server {

    system::role { 'role::rancid::server':
        description => 'Really Awful Notorious CIsco config Differ (sp)'
    }

    include ::rancid

    backup::set { 'rancid': }
}
