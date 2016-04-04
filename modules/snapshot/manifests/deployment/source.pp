class snapshot::deployment::source {
    include snapshot::deployment::dirs

    require ::keyholder
    require ::keyholder::monitoring

    keyholder::agent { 'dumpsdeployment':
        trusted_group   => 'ops',
        key_fingerprint => '86:c9:17:ab:b7:00:79:b5:8a:c5:b5:ee:29:24:c9:2f',
    }
}
