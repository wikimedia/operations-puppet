# == Class mailman3::import_test
#
# Sets up rsync from mailman2 to mailman3 for testing
# the import of mailing lists (T278609).
class mailman3::import_test (
    Stdlib::Fqdn $mailman2_host,
    Stdlib::Fqdn $mailman3_host,
) {
    rsync::quickdatacopy { 'var-lib-mailman':
        source_host => $mailman2_host,
        dest_host   => $mailman3_host,
        auto_sync   => false,
        module_path => '/var/lib/mailman',
    }
}
