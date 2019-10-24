# setup rsync to copy home dirs and tftp data
# for migrating a bastion host
class profile::bastionhost::migration (
    String $source_host = lookup('profile::bastionhost::migration::source_host'),
    String $dest_host = lookup('profile::bastionhost::migration::dest_host'),
){

    if $::fqdn == $dest_host {

        ferm::service { 'bast-migration-rsync':
            proto  => 'tcp',
            port   => '873',
            srange => "@resolve((${source_host}.wikimedia.org))",
        }

        class { '::rsync::server': }

        file { "/srv/${source_host}":
            ensure => 'directory'
        }

        $backup_dirs = ['home', 'tftpboot', 'prometheus']

        $backup_dirs.each |String $backup_dir| {

            file { "/srv/${source_host}/${backup_dir}":
                ensure => 'directory',
            }

            rsync::server::module { $backup_dir:
                path        => "/srv/${source_host}/${backup_dir}",
                read_only   => 'no',
                hosts_allow => "${source_host}.wikimedia.org",
            }
        }
    }
}
