# setup rsync to copy home dirs and tftp data
# for migrating a bastion host
class profile::bastionhost::migration (
    String $src_host = lookup('profile::bastionhost::migration::src_host'),
    String $dst_host = lookup('profile::bastionhost::migration::dst_host'),
){

    $src_fqdn = "${src_host}.wikimedia.org"
    $dst_fqdn = "${dst_host}.wikimedia.org"

    if $::fqdn == $dst_fqdn {

        ferm::service { 'bast-migration-rsync':
            proto  => 'tcp',
            port   => '873',
            srange => "@resolve((${src_fqdn}))",
        }

        class { '::rsync::server': }

        file { "/srv/${src_host}":
            ensure => 'directory'
        }

        $backup_dirs = ['home', 'tftpboot', 'prometheus']

        $backup_dirs.each |String $backup_dir| {

            file { "/srv/${src_host}/${backup_dir}":
                ensure => 'directory',
            }

            rsync::server::module { $backup_dir:
                path        => "/srv/${src_host}/${backup_dir}",
                read_only   => 'no',
                hosts_allow => $src_fqdn,
            }
        }
    }
}
