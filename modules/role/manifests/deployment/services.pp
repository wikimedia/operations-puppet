# === Class role::deployment::services
# Installs the keyholder agent for deploying services
class role::deployment::services (
    $keyholder_user  = 'deploy-service',
    $keyholder_group = 'deploy-service',
    $key_fingerprint  = '6d:54:92:8b:39:10:f5:9b:84:40:36:ef:3c:9a:6d:d8',
) {
    require ::keyholder
    require ::keyholder::monitoring

    keyholder::agent { $keyholder_user:
        trusted_group   => $keyholder_group,
        key_fingerprint => $key_fingerprint,
        key_file        => 'servicedeploy_rsa',
    }
}
