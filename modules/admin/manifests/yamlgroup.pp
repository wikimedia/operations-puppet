# A defined type for group creation / user realization from yaml
#
# === Parameters
#
# [*name*]
#  Yaml group name
#
# [*yamlhash*]
#  Hash that contains valid group data

define admin::yamlgroup(
    $yamlhash={},
)
    {
    include admin

    #explicit error as otherwise it goes forward later
    #complaining of 'invalid hash' which is hard to track down
    if !has_key($yamlhash['groups'], $name) {
        fail("${name} is not a valid group name")
    }

    $gdata = $yamlhash['groups'][$name]
    admin::group { $name:
        ensure => $gdata['ensure'],
        gid    => $gdata['gid'],
        privs  => $gdata['privs'],
    }
}
