class profile::toolforge::jobs_framework_cli(
) {
    # This package may have a configuration file soon. Such declaration may go here in this profile

    package { 'toolforge-jobs-framework-cli':
        ensure => 'latest',
    }
}
