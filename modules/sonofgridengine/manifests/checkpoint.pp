# SPDX-License-Identifier: Apache-2.0
# sonofgridengine/checkpoint.pp

define sonofgridengine::checkpoint(
    $rname   = $title,
    $config  = undef,
) {

    sonofgridengine::resource { $rname:
        dir    => 'checkpoints',
        config => $config,
    }
}
