class role::labs::openstack::nova::common {

    include passwords::misc::scripts
    include role::labs::openstack::nova::wikiupdates

    $novaconfig_pre                       = hiera_hash('novaconfig', {})
    $keystoneconfig                       = hiera_hash('keystoneconfig', {})

    $keystone_host                        = hiera('labs_keystone_host')
    $nova_controller                      = hiera('labs_nova_controller')
    $nova_api_host                        = hiera('labs_nova_api_host')
    $network_host                         = hiera('labs_nova_network_host')
    $status_wiki_host_master              = hiera('status_wiki_host_master')

    $extra_novaconfig = {
        bind_ip                => ipresolve($keystone_host,4),
        keystone_auth_host     => $keystoneconfig['auth_host'],
        keystone_auth_port     => $keystoneconfig['auth_port'],
        keystone_admin_token   => $keystoneconfig['admin_token'],
        keystone_auth_protocol => $keystoneconfig['auth_protocol'],
        auth_uri               => "http://${nova_controller}:5000",
        api_ip                 => ipresolve($nova_api_host,4),
        controller_address     => ipresolve($nova_controller,4),
    }
    $novaconfig = deep_merge($novaconfig_pre, $extra_novaconfig)

    class { '::openstack::common':
        novaconfig                       => $novaconfig,
        instance_status_wiki_host        => $status_wiki_host_master,
        instance_status_wiki_domain      => 'labs',
        instance_status_wiki_page_prefix => 'Nova_Resource:',
        instance_status_wiki_region      => $::site,
        instance_status_dns_domain       => "${::site}.wmflabs",
        instance_status_wiki_user        => $passwords::misc::scripts::wikinotifier_user,
        instance_status_wiki_pass        => $passwords::misc::scripts::wikinotifier_pass,
    }
}

