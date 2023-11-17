<?php
// SPDX-License-Identifier: Apache-2.0
return array(
    'TagManagerContainerStorageDir' => function () {
        // the location where we store the generated javascript or json container files
        return '/tmp/js';
    },
    'TagManagerContainerWebDir' => function (\Psr\Container\ContainerInterface $c) {
        // the path under which the containers are available through the web. this may be different to the storage
        // path if using eg htaccess rewrites
        return '/tmp/js';
    }
);