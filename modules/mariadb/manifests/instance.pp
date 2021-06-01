# Setups additional instances for hosts that hosts more
# than one instance
# * port: Port where to run the instance (required)
# * datadir: datadir mysql config, by default /srv/sqldata.title
# * tmpdir: datadir mysql config, by default /srv/tmp.title
# * socket: socket mysql config, by default /run/mysqld/mysqld.title.sock
# * innodb_buffer_pool_size: config of the same name, it controls how much
#   memory the instace uses. By default, or if it is configured as false,
#   it is unconfigured, and it will default to the one on the common
#   config template (or the mysql default, if not configured there). When
#   configured, it must be passed as a string, such as '11G' or '10000000'.
# * is_critical: config flag to decide whether we page or not for this alert
# * mysqld_extra_config
#   Hash of extra config key => value pairs to render in mysqld.conf.d/${title}.cnf
#   for this instance. Used by the default template config file mariadb/instance.cnf.erb.
#   If you specify a different template, you can choose to use this if you like.
#   Default: {}
define mariadb::instance(
    $port,
    $datadir = 'undefined',
    $tmpdir  = 'undefined',
    $socket  = 'undefined',
    $innodb_buffer_pool_size = false,
    $template = 'mariadb/instance.cnf.erb',
    $is_critical = false,
    $read_only = 1,
    $source_dc = mediawiki::state('primary_dc'),
    $mysqld_extra_configs = {},
) {
    if $datadir == 'undefined' {
        $datadir_instance = "/srv/sqldata.${title}"
    } else {
        $datadir_instance = $datadir
    }
    if $tmpdir == 'undefined' {
        $tmpdir_instance = "/srv/tmp.${title}"
    } else {
        $tmpdir_instance = $tmpdir
    }
    if $socket == 'undefined' {
        $socket_instance = "/run/mysqld/mysqld.${title}.sock"
    } else {
        $socket_instance = $socket
    }

    file { $datadir_instance:
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0755',
    }

    file { $tmpdir_instance:
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0755',
    }

    file { "/etc/mysql/mysqld.conf.d/${title}.cnf":
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template($template),
    }

    mariadb::monitor_replication{ $title:
        socket      => $socket_instance,
        is_critical => $is_critical,
        source_dc   => $source_dc,
    }
    mariadb::monitor_readonly{ $title:
        port      => $port,
        read_only => $read_only,
    }
}
