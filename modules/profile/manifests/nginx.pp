# @summary wrapper profile to install and configure nginx for a profile
# @param ensure whether to ensure the resource
# @param managed If true (the default), changes to Nginx configuration files and site
#   definition files will trigger a restart of the Nginx server. If
#   false, the service will need to be manually restarted for the
#   configuration changes to take effect.
# @param variant nginx in Debian provides three different Debian packages (nginx-light, nginx-extras
#    and nginx-full) which enable different levels of built-in modules (which are provided out of 
#    the box) and available addons (which need to be installed via libnginx-mod-foo). For most use 
#    cases nginx-light will do just fine and it's recommended to stick with it unless you have a 
#    specific need for a module not present there. This reduces risks since less code needs to be 
#    loaded (and also fewer libraries, e.g. nginx-extras ships the an image filter which pulls in 
#    libgd). You can see the list of enabled modules via "apt show nginx-foo
# @param tmpfs_size The tmpfs_size
class profile::nginx (
    Wmflib::Ensure                  $ensure     = lookup('profile::nginx::ensure'),
    Boolean                         $managed    = lookup('profile::nginx::managed'),
    Enum['full', 'extras', 'light'] $variant    = lookup('profile::nginx::variant'),
    String                          $tmpfs_size = lookup('profile::nginx::tmpfs_size'),
) {
    class {'nginx':
        ensure     => $ensure,
        managed    => $managed,
        variant    => $variant,
        tmpfs_size => $tmpfs_size,
    }
}
