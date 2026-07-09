# SPDX-License-Identifier: Apache-2.0
# A device-class entry for lvmd.yaml, keys are passed through verbatim.
# See https://github.com/topolvm/topolvm/blob/v0.38.1/docs/lvmd.md
# The thin provisioning keys are not in that document, but are accepted at
# this version, see pkg/lvmd/types/types.go in the same tree.
type Profile::Kubernetes::Lvmd_device_class = Struct[{
    'name'                       => String[1],
    'volume-group'               => String[1],
    Optional['default']          => Boolean,
    Optional['spare-gb']         => Integer[0],
    Optional['stripe']           => Integer[1],
    Optional['stripe-size']      => String[1],
    Optional['lvcreate-options'] => Array[String[1]],
    Optional['type']             => Enum['thick', 'thin'],
    Optional['thin-pool']        => Struct[{
        'name'                => String[1],
        'overprovision-ratio' => Float[1.0],
    }],
}]
