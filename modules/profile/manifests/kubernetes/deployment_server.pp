# Class makes sure we got a deployment server ready
class profile::kubernetes::deployment_server(
    Hash[String, Any] $services = lookup('profile::kubernetes::deployment_server::services', {default_value => {}}),
    Hash[String, Any] $tokens   = lookup('profile::kubernetes::deployment_server::tokens', {default_value => {}}),
    String $git_owner           = lookup('profile::kubernetes::deployment_server::git_owner'),
    String $git_group           = lookup('profile::kubernetes::deployment_server::git_group'),
){
    include profile::kubernetes::deployment_server::helmfile
    class { '::helm': }

    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    $envs = {
        'eqiad'         => 'kubemaster.svc.eqiad.wmnet',
        'codfw'         => 'kubemaster.svc.codfw.wmnet',
        'staging-eqiad' => 'kubestagemaster.svc.eqiad.wmnet',
        'staging-codfw' => 'kubestagemaster.svc.codfw.wmnet',
        'staging'       => 'kubestagemaster.svc.codfw.wmnet',
    }

    $real_services = deep_merge($services, $tokens)

    # Now populate the /etc/kubernetes/ kubeconfig resources
    $envs.each |String $env, String $master_host| {
        $real_services.each |String $service, Hash $data| {
            # lint:ignore:variable_scope
            if has_key($data, 'username') and has_key($data, 'token') {
                k8s::kubeconfig { "/etc/kubernetes/${service}-${env}.config":
                    master_host => $master_host,
                    username    => $data['username'],
                    token       => $data['token'],
                    group       => $data['group'],
                    mode        => $data['mode'],
                    namespace   => $data['namespace'],
                }
            }
            # lint:endignore
        }
    }
    # Add a script to profile.d with functions to set the configuration for kubernetes.
    file { '/etc/profile.d/kube-env.sh':
        ensure  => present,
        content => template('profile/kubernetes/kube-env.sh.erb'),
        mode    => '0555',
    }
}
