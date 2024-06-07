# yaml config and convenience script to set credentials for openstack access
define openstack::util::envscript(
    String                     $region,
    Stdlib::Fqdn               $keystone_api_fqdn,
    String                     $os_user,
    String                     $os_password,
    Stdlib::Port               $keystone_api_port      = 25000,
    String                     $keystone_api_interface = 'public',
    Optional[Stdlib::Unixpath] $scriptpath             = undef,
    String                     $os_db_password         = '',
    Stdlib::Filemode           $yaml_mode              = '0440',
    Optional[Array[Stdlib::Unixpath]] $clouds_files    = undef,
    Optional[String]           $os_project             = undef,
    Optional[String]           $os_project_domain_id   = undef,
    Optional[String]           $os_user_domain_id      = undef,
    Optional[String]           $os_system_scope        = undef,
    Boolean                    $do_script              = true,
  ) {
    if $clouds_files {
        $clouds_files.each |$clouds_file| {
            concat::fragment { "${clouds_file}_${title}":
                target  => $clouds_file,
                content => template('openstack/util/clouds_fragment.yaml.erb'),
            }
        }
    }

    if $do_script {
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
}
