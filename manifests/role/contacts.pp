# manifests/role/contacts.pp
class role::contacts {

    system::role { 'role::contacts': description => 'Contacts server' }

    class { '::contacts':
        db_host         => 'dbproxy1001.eqiad.wmnet',
        db_name_civicrm => 'contacts_civicrm',
        db_name_drupal  => 'contacts_drupal',
        db_user         => 'contacts',
    }

    ferm::service { 'contacts_http':
        proto => 'tcp',
        port  => '80',
    }

}

