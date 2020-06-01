# filtertags: labs-project-deployment-prep
class profile::swift::stats_reporter (
    Wmflib::Ensure $ensure = present, # lint:ignore:wmf_styleguide
    String $swift_cluster = lookup('profile::swift::cluster'),
    Hash[String, Hash] $accounts = lookup('profile::swift::accounts'),
    Hash[String, String] $credentials = lookup('profile::swift::accounts_keys'),
) {
    class { '::swift::stats::dispersion':
        ensure        => $ensure,
        swift_cluster => $swift_cluster,
    }

    class { '::swift::stats::accounts':
        ensure        => $ensure,
        swift_cluster => $swift_cluster,
        accounts      => $accounts,
        credentials   => $credentials,
    }
}
