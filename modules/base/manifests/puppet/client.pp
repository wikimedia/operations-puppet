class base::puppet::client(
    $servername,
    $ssldir,
    $certname = undef,
) {
    base::puppet::config { 'main':
        prio    => 10,
        content => template('base/puppet.conf.d/10-main.conf.erb'),
    }
}
