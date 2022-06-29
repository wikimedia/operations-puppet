# SPDX-License-Identifier: Apache-2.
#
define prometheus::ganeti(
    String $dest,
    Array[String] $clusters,
    Stdlib::Port $port = 8080,
    Hash $labels = {},
) {
    if !$clusters.empty {
        $targets = $clusters.map |$target| { "${target}:${port}" }
        $data = {
            'targets' => $targets,
            'labels'  => $labels,
        }.flatten

        file { $dest:
            ensure  => stdlib::ensure(!$data.empty, 'file'),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "# This file is managed by puppet\n${data.to_yaml}\n"
        }
    }
}
