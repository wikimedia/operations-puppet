# == Class cdh::mahout
# Installs mahout package.  You should only need to include this on
# nodes where users will run the mahout executable, i.e. client submission nodes.
#
class cdh::mahout {
    package { 'mahout':
        ensure => 'installed',
    }
}
