# Class makes sure we got a deployment server ready
class profile::kubernetes::deployment_server(
    Hash[String, Any] $services    = lookup('profile::kubernetes::deployment_server::services', {default_value => {}}),
    Hash[String, Any] $tokens      = lookup('profile::kubernetes::deployment_server::tokens', {default_value => {}}),
    String $git_owner              = lookup('profile::kubernetes::deployment_server::git_owner'),
    String $git_group              = lookup('profile::kubernetes::deployment_server::git_group'),
    Boolean $packages_from_future  = lookup('profile::kubernetes::deployment_server::packages_from_future', {default_value => false}),

){
    include profile::kubernetes::deployment_server::helmfile
    include profile::kubernetes::deployment_server::mediawiki
    class { '::helm': }
    class { '::k8s::client':
        packages_from_future => $packages_from_future,
    }

    ensure_packages('istioctl')

    $kube_clusters = {
        'main' => {
            'eqiad'         => 'kubemaster.svc.eqiad.wmnet',
            'codfw'         => 'kubemaster.svc.codfw.wmnet',
            'staging-eqiad' => 'kubestagemaster.svc.eqiad.wmnet',
            'staging-codfw' => 'kubestagemaster.svc.codfw.wmnet',
            # This represents the active staging cluster currently used by deployment tools (helmfile)
            'staging'       => 'kubestagemaster.svc.eqiad.wmnet',
        },
        'ml-serve' => {
            'ml-serve-eqiad' => 'ml-ctrl.svc.eqiad.wmnet',
            'ml-serve-codfw' => 'ml-ctrl.svc.codfw.wmnet',
        },
    }

    # For each cluster, define a map between its codename and:
    # - Its kube-api endpoint fqdn.
    # - The data structure containing k8s tokens for its cluster group
    #   (all clusters in a group shares the same set of tokens).
    $envs = $kube_clusters.map |$cluster_group, $clusters| {
        $services = deep_merge($services[$cluster_group], $tokens[$cluster_group])
        $clusters.map |$cluster, $master| {
            { $cluster => {'master' => $master, 'services' => $services } }
        }.reduce({}) |$m, $v| { $m.merge($v) }
    }.reduce({}) |$mem, $val| { $mem.merge($val)}

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

    # Used to support the kube-env.sh script. A list of service names is useful
    # to create an auto-complete feature for kube_env.
    $all_service_names = $services.map |$group, $srvs| {
        keys($srvs) }.reduce([]) |$mem, $val| { $mem + $val }

    # Add a script to profile.d with functions to set the configuration for kubernetes.
    file { '/etc/profile.d/kube-env.sh':
        ensure  => present,
        content => template('profile/kubernetes/kube-env.sh.erb'),
        mode    => '0555',
    }
}
