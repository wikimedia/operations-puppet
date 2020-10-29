# @summary a define to add a certificate to the java truststore
# @param path the location of the CA pem file to add to the truststore
# @param storepass the keystore password
define java::cacert (
    Stdlib::Unixpath $path,
    Wmflib::Ensure   $ensure    = 'present',
    String           $storepass = 'changeit',
) {
    include java
    $keystore = $java::default_java_package['version'] ? {
        '7'     => '-keystore /etc/ssl/certs/java/cacerts',
        '8'     => '-keystore /etc/ssl/certs/java/cacerts',
        default => '-cacerts',
    }
    $import_cmd = @("IMPORT"/L)
        /usr/bin/keytool -import -trustcacerts -noprompt ${keystore} \
            -file ${path} -storepass ${storepass} -alias ${title}
        | IMPORT
    $delete_cmd = "/usr/bin/keytool -delete ${keystore} -noprompt -storepass ${storepass} -alias ${title}"
    $validate_cmd = "/usr/bin/keytool -list ${keystore} -noprompt -storepass ${storepass} -alias ${title}"
    if $ensure == 'present' {
        exec {"java__cacert_${title}":
            command => $import_cmd,
            unless  => $validate_cmd,
        }
    } else {
        exec {"java__cacert_${title}":
            command => $delete_cmd,
            onlyif  => $validate_cmd,
        }
    }
}
