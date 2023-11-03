# @param user The docker username
# @param hash The docker password hash
# @param builder_host The builder host
# @param active_node  The active node
# @param standby_node The standby node
# @param ssl_certificate_name The acme cert to use
# @param index_redirect url to redirect curious people visiting the domain root to
class profile::toolforge::docker::registry(
    String                     $user                 = lookup('docker::username'),
    String                     $hash                 = lookup('docker::password_hash'),
    Stdlib::Host               $builder_host         = lookup('docker::builder_host'),
    Stdlib::Host               $active_node          = lookup('profile::toolforge::docker::registry::active_node'),
    Stdlib::Host               $standby_node         = lookup('profile::toolforge::docker::registry::standby_node'),
    String                     $ssl_certificate_name = lookup('profile::toolforge::docker::registry::ssl_certificate_name', {default_value => 'toolforge'}),
    Optional[Stdlib::HTTPSUrl] $index_redirect       = lookup('profile::toolforge::docker::registry::index_redirect', {default_value => undef}),
) {
    acme_chief::cert { $ssl_certificate_name:
        before     => Class['docker::registry'],
        puppet_rsc => Exec['nginx-reload'],
    }

    $builders = dnsquery::a($builder_host)

    class { 'docker::registry':
        storage_backend => 'filebackend',
        datapath        => '/srv/registry',
        config          => {
            'storage' => {
                'delete' => {
                    'enabled' => true,
                },
            },
        },
    }

    class { 'sslcert::dhparam': } # deploys /etc/ssl/dhparam.pem, required by nginx
    class { 'docker::registry::web':
        docker_username      => $user,
        docker_password_hash => $hash,
        allow_push_from      => $builders,
        use_acme_chief_certs => true,
        ssl_certificate_name => $ssl_certificate_name,
        ssl_settings         => ssl_ciphersuite('nginx', 'compat'),
        cors                 => true,
        index_redirect       => $index_redirect,
    }

    # This may deliberately be un-set for some cases, like toolsbeta
    if $standby_node {
        # make sure we have a backup server ready to take over
        rsync::quickdatacopy { 'docker-registry-sync':
            ensure      => present,
            auto_sync   => true,
            source_host => $active_node,
            dest_host   => $standby_node,
            module_path => '/srv/registry',
            progress    => true,
            delete      => true,
        }
    }

}
