# Class: role::archiva
#
# Installs Apache Archiva and
# sets up a cron job to symlink .jar files to
# a git-fat store.
#
class role::archiva {
    system::role { 'archiva': description => 'Apache Archiva Host' }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::archiva
    include ::profile::archiva::proxy
}

