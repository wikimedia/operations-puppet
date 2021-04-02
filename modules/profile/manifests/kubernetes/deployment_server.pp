# Class makes sure we got a deployment server ready
class profile::kubernetes::deployment_server(
    Hash[String, Any] $services = lookup('profile::kubernetes::deployment_server::services', {default_value => {}}),
    Hash[String, Any] $tokens   = lookup('profile::kubernetes::deployment_server::tokens', {default_value => {}}),
    String $git_owner           = lookup('profile::kubernetes::deployment_server::git_owner'),
    String $git_group           = lookup('profile::kubernetes::deployment_server::git_group'),
    Boolean $packages_from_future = lookup('profile::kubernetes::deployment_server::packages_from_future', {default_value => false}),

){
    include profile::kubernetes::deployment_server::helmfile
    class { '::helm': }
    class { '::k8s::client':
        packages_from_future => $packages_from_future,
    }

    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    $real_services = deep_merge($services, $tokens)
    $ml_services = filter($real_services) |String $service, Hash $data| {
        $service == 'admin'
    }

    $envs = {
        'eqiad'          => { 'master' => 'kubemaster.svc.eqiad.wmnet', 'services' => $real_services },
        'codfw'          => { 'master' => 'kubemaster.svc.codfw.wmnet', 'services' => $real_services },
        'staging-eqiad'  => { 'master' => 'kubestagemaster.svc.eqiad.wmnet', 'services' => $real_services },
        'staging-codfw'  => { 'master' => 'kubestagemaster.svc.codfw.wmnet', 'services' => $real_services },
        # This represents the active staging cluster currently used by deployment tools (helmfile)
        'staging'        => { 'master' => 'kubestagemaster.svc.eqiad.wmnet', 'services' => $real_services },
        # ML clusters
        'ml-serve-eqiad' => { 'master' => 'ml-ctrl.svc.eqiad.wmnet', 'services' => $ml_services },
        'ml-serve-codfw' => { 'master' => 'ml-ctrl.svc.codfw.wmnet', 'services' => $ml_services },
    }

    # Now populate the /etc/kubernetes/ kubeconfig resources
    $envs.each |String $env, Hash $env_data| {
        $env_data['services'].each |String $service, Hash $data| {
            # lint:ignore:variable_scope
            if has_key($data, 'username') and has_key($data, 'token') {
                k8s::kubeconfig { "/etc/kubernetes/${service}-${env}.config":
                    master_host => $env_data['master'],
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
