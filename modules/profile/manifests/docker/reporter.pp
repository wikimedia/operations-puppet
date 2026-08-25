# SPDX-License-Identifier: Apache-2.0
# @summary This profile installs docker-report, and runs the report with the required frequency.
# @param proxy the http procy to use if any
# @param generate_reports if we should generate reports
class profile::docker::reporter(
    Boolean                   $generate_reports = lookup('profile::docker::reporter::generate_reports'),
    Optional[Stdlib::HTTPUrl] $proxy            = lookup('http_proxy'),
) {
    include profile::docker::reporter::credentials

    ensure_packages(['python3-docker-report'])
    $report_ensure = $generate_reports.bool2str('present', 'absent')

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
