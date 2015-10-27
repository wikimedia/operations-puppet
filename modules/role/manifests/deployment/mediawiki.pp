# === Class role::deployment::mediawiki
# Installs the keyholder agent for mediawiki
class role::deployment::mediawiki(
    $keyholder_user = 'mwdeploy',
    $keyholder_group = 'wikidev',
    $key_fingerprint = 'f5:18:a3:44:77:a2:31:23:cb:7b:44:e1:4b:45:27:11',
) {
    require ::keyholder
    require ::keyholder::monitoring

    keyholder::agent { $keyholder_user:
        trusted_group   => $keyholder_group,
        key_fingerprint => $key_fingerprint,
    }
}
