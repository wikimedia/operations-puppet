class contacts (
    $db_host,
    $db_name_civicrm,
    $db_name_drupal,
    $db_user,
) {

    # document root
    file { [ '/srv/org','/srv/org/wikimedia','/srv/org/wikimedia/contacts']:
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
    }

    # db passes from private repo
    include passwords::contacts

    # settings for CiviCRM
    file { '/srv/org/wikimedia/contacts/sites/default/civicrm.settings.php':
        ensure  => present,
        owner   => 'root',
        group   => 'www-data',
        mode    => '0440',
        content => template(''),
    }

    # settings for Drupal
    file { '/srv/org/wikimedia/contacts/sites/default/settings.php':
        ensure  => present,
        owner   => 'root',
        group   => 'www-data',
        mode    => '0440',
        content => template(''),
    }

}
