class role::swift::swiftrepl (
  $ensure = lookup('role::swift::swiftrepl::ensure', { 'default_value' => 'present' }), # lint:ignore:wmf_styleguide
) {
    system::role { 'swift::swiftrepl':
        description => 'swift replication for mediawiki filebackend',
    }

    include ::profile::standard

    $source_site = $::site
    case $source_site {
        'eqiad': {
            $destination_site = 'codfw'
        }
        'codfw': {
            $destination_site = 'eqiad'
        }
        default: { fail("Unsupported source site ${::site}") }
    }

    class { '::swift::swiftrepl':
        ensure           => $ensure,
        destination_site => $destination_site,
        source_site      => $source_site,
    }
}
