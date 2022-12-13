# @since 2.0.0
type Postfix::Type::Lookup::MySQL::Host = Variant[Tuple[Enum['unix'], Stdlib::Absolutepath], Tuple[Enum['inet'], Bodgitlib::Host, Bodgitlib::Port, 2, 3], Tuple[Bodgitlib::Host, Bodgitlib::Port], Bodgitlib::Host]
