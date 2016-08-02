# vim: set ts=4 et sw=4:
class role::labsdb::manager {
    require_package(['python-mysqldb', 'python-yaml'])
    include passwords::misc::scripts
    $mysql_root_pass = $::passwords::misc::scripts::mysql_root_pass
    $mysql_labsdb_root_pass = $::passwords::misc::scripts::mysql_labsdb_root_pass

    file { '/usr/local/sbin/skrillex.py':
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0550',
        source => 'puppet:///modules/role/labsdb/skrillex.py',
    }
    file { '/etc/skrillex.yaml':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('role/labsdb/skrillex.yaml.erb'),
    }
}
