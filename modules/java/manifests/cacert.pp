# @summary a define to add a certificate to the java truststore
# @param path the location of the CA pem file to add to the truststore
# @param storepass the keystore password
define java::cacert (
    Stdlib::Unixpath $path,
    Wmflib::Ensure   $ensure    = 'present',
    String           $storepass = 'changeit',
) {
    $import_cmd = @("IMPORT"/L)
        /usr/bin/keytool -import -trustcacerts -noprompt -cacerts \
            -file ${path} -storepass ${storepass} -alias ${title}
        | IMPORT
    $delete_cmd = "/usr/bin/keytool -delete -cacerts -noprompt -storepass ${storepass} -alias ${title}"
    $validate_cmd = "/usr/bin/keytool -list -cacerts -noprompt -storepass ${storepass} -alias ${title}"
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
