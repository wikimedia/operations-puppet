# == Class profile::analytics::refinery::job::config
# Renders a properties file from $properties suitable for
# using with Refinery jobs configured via ConfigHelper.
#
define profile::analytics::refinery::job::config(
    $properties,
    $path   = $title,
    $ensure = 'present',
) {
    file { $path:
        ensure  => $ensure,
        content => template('profile/analytics/refinery/job/config.properties.erb'),
    }
}