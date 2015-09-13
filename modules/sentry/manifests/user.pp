# == Define: sentry::user
#
# This resource provides an easy way to declare a runtime parameter
# for sentry. It can then be used in sentry <IfDefine> checks.
#
# === Parameters
#
# [*ensure*]
#   If 'present', the environment variable will be defined; if absent,
#   undefined. The default is 'present'.
#
# [*priority*]
#   If you need this var defined before or after other scripts, you can
#   do so by manipulating this value. In most cases, the default value
#   of 50 should be fine.
#
# === Example
#
#  sentry::user { 'HHVM':
#    ensure => present,
#  }
#
define sentry::user(
    $password,
    $email     = $title,
    $superuser = false,
) {
    include ::sentry

    $title_safe  = regsubst($title, '[\W_]', '-', 'G')

    $superuser_arg = $superuser ? {
        true    => '--superuser',
        default => '--no-superuser',
    }

    exec { "sentry_user_${title_safe}":
        command     => "${::sentry::sentry_dir}/bin/sentry createuser --no-input ${superuser_arg} --email ${email} --password ${password}",


        unless => "${::sentry::sentry_dir}/bin/sentry >> import sys, sentry
>> sentry.models.User.objects.filter(email='foo@foo.bar').exists()
True
>> sys.exit(0 if sentry.models.User.objects.filter(email='foo@foo.bar').exists() else 1)>>>
        refreshonly => true,
        user        => 'sentry',
        environment => 'SENTRY_CONF=/etc/sentry/sentry.conf.py',
        subscribe   => Exec['initialize_sentry_database'],
    }
}
