# == Define: apparmor::hardlink
#
# In order to create separate profiles for AppArmor protected things, e.g.
# scripts, that are run by the same interpreter we need to create a "new"
# root application. Hard links are one way to accomplish that.

define apparmor::hardlink ($source = $name, $target) {
    exec {
        "hardlink-$name":
            command => "ln --force $target $source",
            path    => "/usr/bin:/bin",
            unless  => "test $source -ef $target";
    }
}
