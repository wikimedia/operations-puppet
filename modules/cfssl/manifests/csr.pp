# SPDX-License-Identifier: Apache-2.0
# @summary generate a CSR file at $title with the input data
define cfssl::csr (
    String                         $common_name,
    Array[Cfssl::Common_name]      $hosts          = [],
    Array[Cfssl::Name]             $names          = [],
    Cfssl::Key                     $key            = {'algo' => 'ecdsa', 'size' => 256},
    Wmflib::Ensure                 $ensure         = 'present',
) {
    $_names = $names.map |Cfssl::Name $name| {
        {
            'C'  => $name['country'],
            'L'  => $name['locality'],
            'O'  => $name['organisation'],
            'OU' => $name['organisational_unit'],
            'S'  => $name['state'],
        }
    }

    $_hosts = $common_name in $hosts ? {
        true    => $hosts,
        default => $hosts + [$common_name],
    }

    $csr = {
        'CN'    => $common_name,
        'hosts' => $_hosts,
        'key'   => $key,
        'names' => $_names,
    }

    file{ $title:
        ensure  => stdlib::ensure($ensure, 'file'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => $csr.to_json_pretty()
    }
}
