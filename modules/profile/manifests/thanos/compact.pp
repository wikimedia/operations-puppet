class profile::thanos::compact (
    Stdlib::Fqdn $thanos_compact_host = lookup('profile::thanos::compact_host'),
    Hash[String, String] $objstore_account = lookup('profile::thanos::objstore_account'),
    String $objstore_password = lookup('profile::thanos::objstore_password'),
    String $retention = lookup('profile::thanos::retention', { 'default_value' => '270w' }),
) {
    $http_port = 12902

    class { 'thanos::compact':
        run_on_host       => $thanos_compact_host,
        objstore_account  => $objstore_account,
        objstore_password => $objstore_password,
        http_port         => $http_port,
        retention         => $retention,
        concurrency       => 1,
    }

    if $thanos_compact_host == $::fqdn {
        class { 'thanos::compact::prometheus': }
    }
}
