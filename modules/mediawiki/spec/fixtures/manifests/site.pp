class network::constants {
    $external_networks = [
        '91.198.174.0/24',
        '208.80.152.0/22',
        '2620:0:860::/46',
        '198.35.26.0/23',
        '185.15.56.0/22',
        '2a02:ec80::/32',
    ]

    $all_networks = flatten([$external_networks, '10.0.0.0/8'])
}