class openstack::manila::configuration (
    String              $version,
    String              $region,
    Array[Stdlib::Fqdn] $openstack_controllers,
    Stdlib::Fqdn        $keystone_api_fqdn,
    String              $ldap_user_pass,
    Stdlib::Port        $api_bind_port,
    String              $cinder_volume_type,
    String              $db_user,
    String              $db_pass,
    String              $db_name,
    Stdlib::Fqdn        $db_host,
    String              $rabbit_user,
    String              $rabbit_pass,
    String              $user_pass,
    String              $nova_flavor_id,
    String              $network_id,
    String              $subnet_id,
    String              $service_image,
    String              $service_instance_user,
    String              $service_instance_pass,
    String              $metadata_proxy_shared_secret,
    ) {

    file { '/etc/manila/manila.conf':
        owner     => 'manila',
        group     => 'manila',
        mode      => '0640',
        content   => template("openstack/${version}/manila/manila.conf.erb"),
        show_diff => false,    # because it may contain passwords
    }
}
