# yaml config and convenience script to set credentials for openstack access
define openstack::util::envscript(
    String       $region,
    Stdlib::Fqdn $keystone_api_fqdn,
    String       $os_user,
    String       $os_password,
    String       $os_project,
    Stdlib::Port $keystone_api_port = 5000,
    String       $keystone_api_interface = 'public',
    String       $scriptpath = undef,
    String       $os_db_password = '',
    String       $yaml_mode = '0440',
  ) {

    file { "/etc/${title}.yaml":
        content => template('openstack/util/envscript.yaml.erb'),
        mode    => $yaml_mode,
        owner   => 'root',
        group   => 'root',
    }

    $script = $scriptpath ? {
        undef   => "/usr/local/bin/${title}.sh",
        default => $scriptpath,
    }

    file { $script:
        content => template('openstack/util/envscript.sh.erb'),
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
    }
}
