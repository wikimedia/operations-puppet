class role::wmcs::db::wikireplicas::querysampler {
    system::role { $name:
        description => 'simple random-interval query sampler for wikireplicas',
    }

    include profile::wmcs::db::wikireplicas::querysampler
}
