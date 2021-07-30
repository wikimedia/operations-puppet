# Adds docker configuration for specific credentials
# in the file path used as a title.
define docker::credentials(
    String $owner,
    String $group,
    Stdlib::Fqdn $registry,
    String $registry_username,
    String $registry_password,
    Boolean $allow_group = true,
) {
    unless ($name =~ Stdlib::Unixpath) {
        fail("docker::credentials resource name should be a valid unix path, got ${name}")
    }
    $dirmode = $allow_group ? {
        true  => '0550',
        false => '0500'
    }
    $filemode = $allow_group ? {
        true  => '0440',
        false => '0400'
    }
    $directory = dirname($name)
    if (!defined(File[$directory])) {
        file { $directory:
            ensure => directory,
            owner  => $owner,
            group  => $group,
            mode   => $dirmode,
        }
    }
    # uses strict_encode64 since encode64 adds newlines?!
    $docker_auth = inline_template("<%= require 'base64'; Base64.strict_encode64('${registry_username}:${registry_password}') -%>")
    $docker_config = {
        'auths' => {
            "https://${registry}" => {
                'auth' => $docker_auth,
            },
        },
    }
    file { $name:
        ensure    => present,
        content   => ordered_json($docker_config),
        owner     => $owner,
        group     => $group,
        mode      => $filemode,
        show_diff => false,
    }
}
