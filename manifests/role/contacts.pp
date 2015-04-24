class role::contacts {

    system::role { 'role::contacts': description => '(retired) contacts.wikimedia.org - Drupal/CiviCRM' }

        include role::backup::host
        backup::set {'srv-org-wikimedia-contacts': }

}
