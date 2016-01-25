# === Class role::deployment::salt_masters
# Installs deployment-related data to the salt master
class role::deployment::salt_masters(
    $deployment_server = undef
    ) {

    $deployment_host = $deployment_server ? {
        undef   => hiera('deployment_server', 'tin.eqiad.wmnet'),
        default => $deployment_server
    }
    $deployment_config = {
        'parent_dir' => '/srv/deployment',
        'servers'    => {
            'eqiad'  => $deployment_host,
            'codfw'  => $deployment_host,
        },
        'redis'      => {
            'host'                   => $deployment_host,
            'port'                   => '6379',
            'db'                     => '0',
            'socket_connect_timeout' => '5',
        },
    }

    class { '::role::deployment::config': }

    class { 'deployment::salt_master':
        repo_config       => $role::deployment::config::repo_config,
        deployment_config => $deployment_config,
    }
}
