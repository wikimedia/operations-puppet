class profile::toolforge::jobs_framework_cli(
) {
    package { 'toolforge-jobs-framework-cli':
        ensure => 'latest',
    }

    $api_url = "api_url: https://api.svc.${::wmcs_project}.eqiad1.wikimedia.cloud:30003/jobs/api/v1"
    $kubeconfig = 'kubeconfig: ~/.kube/config'

    file { '/etc/toolforge-jobs-framework-cli.cfg':
        ensure  => present,
        content => inline_template("# file by puppet\n<%= @api_url %>\n<%= @kubeconfig %>\n")
    }
}
