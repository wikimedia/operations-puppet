# @!visibility private
module PuppetX # rubocop:disable Style/ClassAndModuleChildren
  # @!visibility private
  module Bodgit # rubocop:disable Style/ClassAndModuleChildren
    # @!visibility private
    module Postfix # rubocop:disable Style/ClassAndModuleChildren
      # Postfix type utility methods
      module Util
        # Match the following provided it's not preceeded by a $:
        #
        # * `$foo_bar_baz`
        # * `$(foo_bar_baz)`
        # * `${foo_bar_baz}`
        # * `${foo_bar_baz?value}`
        # * `${foo_bar_baz:value}`
        #
        # However, due to Ruby 1.8.7 we have to do this backwards as there's
        # no look-behind operator without pulling in Oniguruma. So anywhere
        # this Regexp is used the target string needs to be reversed and then
        # any captures need to be un-reversed again.
        PARAMETER_REGEXP = %r{
          (?:
            (
              [[:alnum:]]+
              (?:
                _
                [[:alnum:]]+
              )*
            )
            |
            \)
            (
              [[:alnum:]]+
              (?:
                _
                [[:alnum:]]+
              )*
            )
            \(
            |
            \}
            (?:
              (
                [^?:]+
              )
              (
                [?:]
              )
            )?
            (
              [[:alnum:]]+
              (?:
                _
                [[:alnum:]]+
              )*
            )
            \{
          )
          \$
          (?!
            \$
          )
        }x.freeze

        # Expand variables where possible
        def expand(value)
          v = value.reverse.clone
          loop do
            old = v.clone
            v.gsub!(PARAMETER_REGEXP) do |_s|
              replacement = Regexp.last_match(0)
              # We want all non-nil $1..n captures
              match = $LAST_MATCH_INFO.to_a[1..-1].compact.reverse.map { |x| x.reverse }
              types = catalog.resources.select do |r|
                r.is_a?(Puppet::Type.type(:postfix_main)) && r.should(:ensure) == :present
              end
              types.each do |r|
                if r.name.eql?(match[0]) && !(match[1])
                  replacement = r.should(:value).reverse
                end
              end
              replacement
            end
            break if old.eql?(v)
          end
          v.reverse
        end

        # Generate a list of potential candidates for file dependencies
        def file_autorequires(values)
          requires = []
          values.each do |v|
            case v
            when %r{^(?:\/[^\/]+)+\/?$}
              # File
              requires << v
            when %r{^(?:proxy:)?([a-z]+):((?:\/[^\/]+)+)$}
              # Lookup table
              case Regexp.last_match(1)
              when 'btree', 'hash'
                requires << "#{Regexp.last_match(2)}.db"
              when 'cdb'
                requires << "#{Regexp.last_match(2)}.cdb"
              when 'dbm', 'sdbm'
                requires << "#{Regexp.last_match(2)}.dir"
                requires << "#{Regexp.last_match(2)}.pag"
              when 'lmdb'
                requires << "#{Regexp.last_match(2)}.lmdb"
              else
                # Apart from the above exceptions, target the source file
                requires << Regexp.last_match(2)
              end
            end
          end
          requires
        end

        # Generate a list of variable names
        def value_scan(value)
          value.reverse.scan(PARAMETER_REGEXP).each do |s|
            s.compact!.reverse!
            yield s[0].reverse if block_given?
          end
        end
      end
    end
  end
end
