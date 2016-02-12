class role::rancid {

    system::role { 'role::rancid':
        description => 'Really Awful Notorious CIsco config Differ (sp)'
    }

    include ::rancid
}

