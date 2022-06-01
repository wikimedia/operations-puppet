# SPDX-License-Identifier: Apache-2.0
# sonofgridengine/queue.pp

define sonofgridengine::queue(
    $rname   = $title,
    $config  = undef,
) {

    sonofgridengine::resource { $rname:
        dir    => 'queues',
        config => $config,
    }
}
