# https://contacts.wikimedia.org | http://en.wikipedia.org/wiki/CiviCRM
class misc::outreach::civicrm {

    system::role { 'misc::outreach::civicrm': description => 'contacts.wikimedia.org - Drupal/CiviCRM' }

    file {
        '/etc/apache2/sites-available/contacts.wikimedia.org':
            ensure => present,
            mode   => '0444',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///files/apache/sites/contacts.wikimedia.org';
    }

    apache_site { 'contacts': name => 'contacts.wikimedia.org' }
    install_certificate{ "contacts.wikimedia.org": }
}

