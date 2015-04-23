# https://contacts.wikimedia.org | http://en.wikipedia.org/wiki/CiviCRM
class role::contacts {

    system::role { 'role::contacts': description => 'contacts.wikimedia.org - Drupal/CiviCRM' }

        include role::backup::host
        backup::set {'srv-org-wikimedia-contacts': }

}
