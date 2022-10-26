class profile::toolforge::jobs_framework_cli(
) {
    package { 'toolforge-jobs-framework-cli':
        ensure => 'latest',
    }

    $api_url = "api_url: https://jobs.svc.${::wmcs_project}.eqiad1.wikimedia.cloud:30001/api/v1"
    $kubeconfig = 'kubeconfig: ~/.kube/config'

    file { '/etc/toolforge-jobs-framework-cli.cfg':
        ensure  => present,
        content => inline_template("# file by puppet\n<%= @api_url %>\n<%= @kubeconfig %>\n")
    }
}
