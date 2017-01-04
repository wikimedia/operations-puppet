class cumin::master {
    ::keyholder::agent { "cumin_master":
        trusted_groups => ['root'],
    }
}
