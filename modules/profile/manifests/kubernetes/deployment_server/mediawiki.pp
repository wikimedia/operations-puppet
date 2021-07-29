# Kubernetes mediawiki configuration
# * virtual hosts
# * mcrouter pools

class profile::kubernetes::deployment_server::mediawiki(
    Array[Mediawiki::SiteCollection] $common_sites      = lookup('mediawiki::common_sites'),
    Array[Mediawiki::SiteCollection] $mediawiki_sites   = lookup('mediawiki::sites'),
    Optional[Stdlib::Port::User] $fcgi_port             = lookup('profile::php_fpm::fcgi_port', {'default_value' => undef}),
    String $fcgi_pool                                   = lookup('profile::mediawiki::fcgi_pool', {'default_value' => 'www'}),
    String $domain_suffix                               = lookup('mediawiki::web::sites::domain_suffix', {'default_value' => 'org'}),
    Stdlib::Unixpath $general_dir                       = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
    Hash  $servers_by_datacenter_category               = lookup('profile::mediawiki::mcrouter_wancache::shards'),
    Hash  $redis_shards                                 = lookup('redis::shards'),
    String $docker_password                             = lookup('kubernetes_docker_password'),
    Stdlib::Fqdn $docker_registry                       = lookup('docker::registry'),
){
    file { "${general_dir}/mediawiki":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
    # Generate the apache-config defining yaml, and save it to
    # $general_dir/mediawiki/httpd.yaml
    $fcgi_proxy = mediawiki::fcgi_endpoint($fcgi_port, $fcgi_pool)
    $all_sites = $mediawiki_sites + $common_sites
    class { '::mediawiki::web::yaml_defs':
        path          => "${general_dir}/mediawiki/httpd.yaml",
        siteconfigs   => $all_sites,
        fcgi_proxy    => $fcgi_proxy,
        domain_suffix => $domain_suffix,
    }
    class { 'mediawiki::mcrouter::yaml_defs':
        path                           => "${general_dir}/mediawiki/mcrouter_pools.yaml",
        servers_by_datacenter_category => $servers_by_datacenter_category,
    }
    class { 'mediawiki::nutcracker::yaml_defs':
        path         => "${general_dir}/mediawiki/nutcracker_pools.yaml",
        redis_shards => $redis_shards,
    }

    # Install docker-report in order to be able to list tags remotely
    package { 'python3-docker-report':
        ensure => present,
    }

    # Now install the credentials for the kubernetes docker user so that we can list tags
    # in the restricted namespace. This is ok since the credentials will be guarded by
    # being ran as root, and that is more restrictive than access to the stuff contained
    # in the restricted images.
    # Registry credentials require push privileges
    # uses strict_encode64 since encode64 adds newlines?!
    $docker_auth = inline_template("<%= require 'base64'; Base64.strict_encode64('kubernetes:${docker_password}') -%>")

    $docker_config = {
        'auths' => {
            "${docker_registry}" => {
                'auth' => $docker_auth,
            },
        },
    }

    file { '/root/.docker':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    file { '/root/.docker/config.json':
        content => ordered_json($docker_config),
        owner   => 'root',
        group   => 'docker',
        mode    => '0440',
    }

    # Add a script that updates the mediawiki images.
    file { '/usr/local/sbin/deploy-mwdebug':
        source => 'puppet:///modules/profile/kubernetes/deployment_server/deploy-mwdebug.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0440',
    }
}
