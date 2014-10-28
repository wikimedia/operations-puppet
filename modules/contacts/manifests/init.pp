# https://contacts.wikimedia.org | http://en.wikipedia.org/wiki/CiviCRM
class contacts {

    apache::site { 'contacts.wikimedia.org':
        content => template('apache/sites/contacts.wikimedia.org.erb'),
    }

    ferm::service { 'contacts_http':
        proto => 'tcp',
        port  => '80',
    }

}
