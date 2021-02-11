class profile::mediawiki::mwdebug_homes(
    Stdlib::Fqdn $backup_mwdebug_host = lookup('profile::mediawiki::mwdebug_homes::backup_mwdebug_host'),
){
    rsync::quickdatacopy { 'mwdebug-home':
        ensure      => present,
        auto_sync   => false,
        source_host => $backup_mwdebug_host,
        dest_host   => $::fqdn,
        module_path => '/srv/userhomes',
    }
}
