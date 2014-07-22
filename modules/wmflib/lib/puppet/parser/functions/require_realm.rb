module Puppet::Parser::Functions
  newfunction(
    :require_realm,
    :doc  => <<-END
      Validate that the host realm is equal to some value.
      Abort catalog compilation if not.

      Examples:

         require_realm('labs')
         require_realm('production')

    END
  ) do |args|
    unless args.length == 1 and args.first.is_a? String
      raise Puppet::ParseError, 'require_realm() takes a single string argument'
    end
    unless args.first == lookupvar('realm')
      raise Puppet::ParseError, "Realm #{args.first} required."
    end
  end
end
