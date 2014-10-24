class role::rancid {

    system::role { 'misc::rancid':
        description => 'Really Awful Notorious CIsco config Differ (sp)'
    }

    include ::rancid
}

