# SPDX-License-Identifier: Apache-2.0
# @summary This profile installs docker-report, and runs the report with the required frequency.
# @param proxy the http procy to use if any
# @param generate_reports if we should generate reports
class profile::docker::reporter(
    Boolean                   $generate_reports = lookup('profile::docker::reporter::generate_reports'),
    Optional[Stdlib::HTTPUrl] $proxy            = lookup('http_proxy'),
) {
    $report_ensure = $generate_reports.bool2str('present', 'absent')

    # Ensure /etc/kubernetes/pki is created with proper permissions before the first pki::get_cert call
    # FIXME: https://phabricator.wikimedia.org/T337826
    $cert_dir = '/etc/kubernetes/pki'
    unless defined(File[$cert_dir]) {
        file { $cert_dir:
            ensure => bool2str($generate_reports, 'directory', 'absent'),
            mode   => '0755',
        }
    }

    k8s::fetch_clusters(false).each | String $name, K8s::ClusterConfig $config | {
        $auth_cert = profile::pki::get_cert($config['pki_intermediate_base'], 'debmonitor', {
            'ensure'         => bool2str($generate_reports, 'present', 'absent'),
            'renew_seconds'  => $config['pki_renew_seconds'],
            'outdir'         => $cert_dir,
            'owner'          => 'root',
            # The debmonitor user does not have any organisation attributes (e.g. groups)
            # attached as it is being granted specific (limited) rights via RBAC.
        })

        $kubeconfig_path = "/etc/kubernetes/debmonitor-${name}.config"
        k8s::kubeconfig { $kubeconfig_path:
            ensure      => bool2str($generate_reports, 'present', 'absent'),
            master_host => $config['master'],
            username    => 'debmonitor',
            auth_cert   => $auth_cert,
        }
    }

    ensure_packages(['python3-docker-report'])

    profile::docker::reporter::report {
        default:
            ensure => $report_ensure,
            team   => 'ServiceOps',
            proxy  => $proxy,
            ;
        # Report on base images and production-images.
        # Temporarily absented while testing the new Kubernetes version.
        'base':
            ensure        => absent,
            frequency     => 'daily',
            target        => 'registry',
            rule_filename => 'base_registry_rules.ini',
            ;
        # Report on images used in production on k8s
        # Temporarily absented while testing the new Kubernetes version.
        'k8s':
            ensure        => absent,
            frequency     => 'weekly',
            target        => 'registry',
            rule_filename => 'k8s_registry_rules.ini',
            ;
        # Report on the staging-eqiad kubernetes cluster.
        'wikikube_staging_eqiad':
            frequency           => 'daily',
            team                => 'ServiceOps',
            target              => 'kubernetes',
            k8s_kubeconfig_path => '/etc/kubernetes/debmonitor-staging-eqiad.config',
            rule_filename       => 'wikikube_kubernetes_rules.ini'
            ;
        # Report on the staging-codfw kubernetes cluster.
        'wikikube_staging_codfw':
            frequency           => 'daily',
            hour                => '00:30:00',
            team                => 'ServiceOps',
            target              => 'kubernetes',
            k8s_kubeconfig_path => '/etc/kubernetes/debmonitor-staging-codfw.config',
            rule_filename       => 'wikikube_kubernetes_rules.ini'
            ;
        # Report on the ML staging kubernetes cluster.
        'ml_staging_codfw':
            frequency           => 'daily',
            hour                => '01:00:00',
            team                => 'Machine Learning',
            target              => 'kubernetes',
            k8s_kubeconfig_path => '/etc/kubernetes/debmonitor-ml-staging-codfw.config',
            ;
        # Report on the DSE kubernetes cluster.
        'dse_eqiad':
            frequency           => 'daily',
            hour                => '01:30:00',
            team                => 'Data Platform',
            target              => 'kubernetes',
            k8s_kubeconfig_path => '/etc/kubernetes/debmonitor-dse-k8s-eqiad.config',
            rule_filename       => 'dse_kubernetes_rules.ini'
            ;
        # Report on the AUX eqiad kubernetes cluster.
        'aux_eqiad':
            frequency           => 'daily',
            hour                => '02:00:00',
            team                => 'Infrastructure Foundations',
            target              => 'kubernetes',
            k8s_kubeconfig_path => '/etc/kubernetes/debmonitor-aux-k8s-eqiad.config',
            ;
        # Report on the AUX codfw kubernetes cluster.
        'aux_codfw':
            frequency           => 'daily',
            hour                => '02:30:00',
            team                => 'Infrastructure Foundations',
            target              => 'kubernetes',
            k8s_kubeconfig_path => '/etc/kubernetes/debmonitor-aux-k8s-codfw.config',
            ;
        # Report on the Wikikube eqiad kubernetes cluster.
        'wikikube_eqiad':
            frequency           => 'daily',
            hour                => '03:00:00',
            team                => 'ServiceOps',
            target              => 'kubernetes',
            k8s_kubeconfig_path => '/etc/kubernetes/debmonitor-eqiad.config',
            rule_filename       => 'wikikube_kubernetes_rules.ini'
            ;
        # Report on the Wikikube codfw kubernetes cluster.
        'wikikube_codfw':
            frequency           => 'daily',
            hour                => '04:00:00',
            team                => 'ServiceOps',
            target              => 'kubernetes',
            k8s_kubeconfig_path => '/etc/kubernetes/debmonitor-codfw.config',
            rule_filename       => 'wikikube_kubernetes_rules.ini'
            ;
        # Report on the ML serve eqiad kubernetes cluster.
        'ml_serve_eqiad':
            frequency           => 'daily',
            hour                => '05:00:00',
            team                => 'Machine Learning',
            target              => 'kubernetes',
            k8s_kubeconfig_path => '/etc/kubernetes/debmonitor-ml-serve-eqiad.config',
            ;
        # Report on the ML serve codfw kubernetes cluster.
        'ml_serve_codfw':
            frequency           => 'daily',
            hour                => '06:00:00',
            team                => 'Machine Learning',
            target              => 'kubernetes',
            k8s_kubeconfig_path => '/etc/kubernetes/debmonitor-ml-serve-codfw.config',
            ;
    }
}
