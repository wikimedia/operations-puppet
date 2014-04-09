# == Class logster
# Installs logster package.
# Use logster::job to set up
# a cron job to tail a log file.
class logster {
    package { 'logster':
        ensure => 'installed',
    }
}
