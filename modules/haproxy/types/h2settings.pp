# header_table_size
#   sets the HTTP/2 dynamic header table size
# initial_window_size
#   sets the HTTP/2 initial window size
# max_concurrent_streams
#   sets the HTTP/2 maximum number of concurrent streams per connection
type Haproxy::H2settings = Struct[{
    'header_table_size'      => Integer[0],
    'initial_window_size'    => Integer[0],
    'max_concurrent_streams' => Integer[0],
}]
