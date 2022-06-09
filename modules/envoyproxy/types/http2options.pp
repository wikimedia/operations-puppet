# SPDX-License-Identifier: Apache-2.0
type Envoyproxy::Http2options = Struct[{
    'max_concurrent_streams'         => Integer[1, 2147483647],
    'initial_stream_window_size'     => Integer[65535, 2147483647],
    'initial_connection_window_size' => Integer[65535, 2147483647],
}]
