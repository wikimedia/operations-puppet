# SPDX-License-Identifier: Apache-2.0
# @summary a define to add a certificate to the system java truststore
# or to a custom one.
# @param path the location of the CA pem file to add to the truststore
# @param ensure ensurable
# @param storepass the keystore password
# @param owner user to use for file permissions
# @param group group to use for file permissions
# @param keystore_path optional, the keystore to create (instead of using
# the system one).
define java::cacert (
    Stdlib::Unixpath           $path,
    Wmflib::Ensure             $ensure        = 'present',
    String                     $storepass     = 'changeit',
    String                     $owner         = 'root',
    String                     $group         = 'root',
    Optional[Stdlib::Unixpath] $keystore_path = undef,
) {
    Class['java'] -> Java::Cacert<| |>

    if $keystore_path != undef {
        $keystore = "-keystore ${keystore_path}"
        $trust_cacert = ''
    } else {
        $keystore = $java::default_java_package['version'] ? {
            '7'     => '-keystore /etc/ssl/certs/java/cacerts',
            '8'     => '-keystore /etc/ssl/certs/java/cacerts',
            default => '-cacerts',
        }
        $trust_cacert = '-trustcacerts'
    }
    $import_cmd = @("IMPORT"/L)
        /usr/bin/keytool -import ${trust_cacert} -noprompt ${keystore} \
            -file ${path} -storepass ${storepass} -alias ${title}
        | IMPORT
    $delete_cmd = "/usr/bin/keytool -delete ${keystore} -noprompt -storepass ${storepass} -alias ${title}"
    $validate_cmd = "/usr/bin/keytool -list ${keystore} -noprompt -storepass ${storepass} -alias ${title}"
    if $ensure == 'present' {
        exec {"java__cacert_${title}":
            command => $import_cmd,
            user    => 'root',
            group   => 'root',
            unless  => $validate_cmd,
        }
    } else {
        exec {"java__cacert_${title}":
            command => $delete_cmd,
            user    => 'root',
            group   => 'root',
            onlyif  => $validate_cmd,
        }
    }
    if $keystore_path {
        ensure_resource('file', $keystore_path, {
            ensure  => stdlib::ensure($ensure, 'file'),
            owner   => $owner,
            group   => $group,
        })
        Exec["java__cacert_${title}"] {
            before => File[$keystore_path]
        }
    }
}
