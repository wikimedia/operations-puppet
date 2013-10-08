class mysql_wmf::conf inherits mysql_wmf {
    $db_clusters = {
        'fundraisingdb' => {
            'innodb_log_file_size' => '500M'
        },
        'm1' => {
            'innodb_log_file_size' => '500M'
        },
    }

    if $::db_cluster =~ /^fundraisingdb$/ {
        $mysql_myisam = true
    }
    else {
        $mysql_myisam = false
    }

    if $::db_cluster {
        $ibsize = $::db_clusters[$::db_cluster]['innodb_log_file_size']
    } else {
        $ibsize = '500M'
    }

    # enable innodb_file_per_table if it's a fundraising or otrs database
    if $::db_cluster =~ /^(fundraisingdb|m)/ {
        $innodb_file_per_table = true
    } else {
        $innodb_file_per_table = false
    }

    # collect all the changes to the dbs used by the summer researchers

    # FIXME: please qualify these globals with something descriptive, e.g. $mysql_read_only
    # FIXME: defaults aren't set, so template expansion is currently broken

        $disable_binlogs = false
        $long_timeouts = false
        $enable_unsafe_locks = false
        $large_slave_trans_retries = false
        if $::writable {
            $read_only = false
        } else {
            $read_only = true
        }

    if ! $skip_name_resolve {
        $skip_name_resolve = true
    }

    file { '/etc/my.cnf':
        content => template('mysql_wmf/prod.my.cnf.erb')
    }

    file { '/etc/mysql/my.cnf':
        ensure => link,
        target => '/etc/my.cnf';
    }

    file {
        '/usr/local/sbin/snaprotate.pl':
            owner  => root,
            group  => root,
            mode   => '0555',
            source => 'puppet:///modules/mysql_wmf/snaprotate.pl'
    }
}
