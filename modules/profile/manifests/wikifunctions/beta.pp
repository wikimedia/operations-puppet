# SPDX-License-Identifier: Apache-2.0
# Monitoring checks for the Wikifunctions Beta Cluster instance.
class profile::wikifunctions::beta () {
    $vhost = 'wikifunctions.beta.wmflabs.org'
    prometheus::blackbox::check::http { $vhost:
        instance_label     => $vhost,
        ip_families        => ['ip4'],
        ip4                => ipresolve($vhost, 4),
        path               => '/w/api.php?action=wikilambda_health_check&format=json',
        team               => 'abstract-wikipedia',
        timeout            =>  '10s',
        severity           => 'warning',
        # This health check runs multiple tests against the orchestrator. It only returns
        # success: true if all tests are run and passed.
        body_regex_matches => ['"success":"true"'],
    }
}
