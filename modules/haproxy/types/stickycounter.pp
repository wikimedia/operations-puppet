# In a haproxy built with defaults, there can be at most three of these.  Order matters.
type Haproxy::Stickycounter = Struct[{
    'context'   => Enum['tcp-request connection', 'http-request', 'http-response'],
    'key'       => Enum['src'],  # TODO support others, or perhaps just make this a String
    'table'     => Optional[String],
    'condition' => Optional[String],  # e.g. "if cache_miss or cache_pass"
}]
