# setup rsync for misc. apps data 
class profile::misc_apps::rsync (
    Stdlib::Fqdn $src_host = lookup('profile::misc_apps::rsync::src_host'),
    Stdlib::Fqdn $dst_host = lookup('profile::misc_apps::rsync::dst_host'),
){

    if $::fqdn == $dst_host {

        ferm::service { 'miscapps-rsync':
            proto  => 'tcp',
            port   => '873',
            srange => "(@resolve((${src_host})) @resolve((${src_host}), AAAA))",
        }

        class { '::rsync::server': }

        rsync::server::module { 'miscapps-srv':
            path        => '/srv/',
            read_only   => 'no',
            hosts_allow => $src_host,
        }
    }
}
