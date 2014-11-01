# Class: base::packages::emacs
#
# Installs emacs package
class base::packages::emacs {
    package { 'emacs23':
        ensure => 'installed',
        alias  => 'emacs',
    }
}