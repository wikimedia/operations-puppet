# This is the api service for Openstack Nova.
# It provides a REST api that  Wikitech and Horizon use to manage VMs.
class openstack::nova::api::service(
    $version,
    $active,
    Stdlib::Port $api_bind_port,
    Stdlib::Port $metadata_bind_port,
    String       $dhcp_domain,
    Integer      $compute_workers,
    Stdlib::Fqdn $keystone_fqdn,
    String       $observer_password,
    String       $region,
    Array[Stdlib::IP::Address] $cloud_cumin_bastions,
    ) {

    class { "openstack::nova::api::service::${version}":
        api_bind_port      => $api_bind_port,
        metadata_bind_port => $metadata_bind_port,
        compute_workers    => $compute_workers,
    }

    service { 'nova-api':
        ensure    => $active,
        subscribe => [
                      File['/etc/nova/nova.conf'],
                      File['/etc/nova/policy.yaml'],
                      File['/etc/nova/vendor_data.json'],
            ],
        require   => Package['nova-api'];
    }

    # Prepare to inject cumin key; this is useful on unpuppetized VMs
    #  but may drift out of usefulness when cumin infra is updated.
    $cumin_pubkey = secret('keyholder/cumin_openstack_master.pub')
    $cumin_bastions = join($cloud_cumin_bastions, ',')

    # vendor data needs to be in json format. vendordata.txt
    #  contains all of our cloud-init settings and firstboot script;
    #  jamming it all into one giant json field seems to work.
    $vendordata_file_contents = template('openstack/nova/vendordata.txt.erb')
    $vendor_data = {
        'domain'     => $dhcp_domain,
        'cloud-init' => $vendordata_file_contents,
    }

    file { '/etc/nova/vendor_data.json':
        content => to_json_pretty($vendor_data),
        owner   => 'nova',
        group   => 'nogroup',
        mode    => '0444',
        require => Package['nova-common'],
        notify  => Service['nova-api-metadata', 'nova-api'];
    }
}
