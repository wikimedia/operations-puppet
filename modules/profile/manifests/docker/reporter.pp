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
            ensure    => absent,
            frequency => 'daily',
            target    => 'registry',
            ;
        # Report on images used in production on k8s
        # Temporarily absented while testing the new Kubernetes version.
        'k8s':
            ensure    => absent,
            frequency => 'weekly',
            target    => 'registry',
            ;
        # Report on the staging-eqiad kubernetes cluster.
        'wikikube_staging_eqiad':
            frequency           => 'daily',
            target              => 'kubernetes',
            k8s_kubeconfig_path => '/etc/kubernetes/debmonitor-staging-eqiad.config',
            rule_filename       => 'wikikube_kubernetes_rules.ini'
            ;
    }
}
