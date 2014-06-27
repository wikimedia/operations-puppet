# https://racktables.wikimedia.org

class misc::racktables {

    include mysql,
        passwords::racktables

    # variables
    $racktables_db_host = 'db1001.eqiad.wmnet'
    $racktables_db = 'racktables'

    file { '/srv/org/wikimedia/racktables/wwwroot/inc/secret.php':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('racktables/racktables.config.erb'),
    }

}
