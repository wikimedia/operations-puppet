class mysql_wmf::client::default_charset_binary {
    # ubuntu's stock mysql client defaults to latin1 charsets
    # this overrides it to binary
    file {
        '/etc/mysql/conf.d/charset.cnf':
            owner  => root,
            group  => root,
            mode   => '0644',
            source => 'puppet:///modules/mysql_wmf/charset.cnf';
    }
}
