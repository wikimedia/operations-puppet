#

class role::servermon {
    include private::servermon

    $db_user = $private::servermon::db_user
    $db_password = $private::servermon::db_password

    class { '::servermon':
        ensure      => 'present',
        directory   => '/srv/deployment/servermon/servermon',
        db_engine   => 'mysql',
        db_name     => 'puppet',
        db_user     => $db_user,
        db_password => $db_password,
        db_host     => 'db1001.eqiad.wmnet',
        admins      => '("Ops Team", "ops@lists.wikimedia.org")',
    }

    deployment::target {'servermon': }
}
