# Class: role::archiva
#
# Installs Apache Archiva and
# sets up a cron job to symlink .jar files to
# a git-fat store.
#
class role::archiva {
    class { '::archiva':         }
    class { '::archiva::gitfat': }
}