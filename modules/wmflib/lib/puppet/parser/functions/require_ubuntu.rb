module Puppet::Parser::Functions
  newfunction(
    :require_ubuntu,
    :doc  => <<-END
      Validate that the host Ubuntu version satisfies a version
      check. Abort catalog compilation if not.

      Examples:

         require_ubuntu('trusty')    # Fail unless Trusty
         require_ubuntu('> trusty')  # Fail unless Trusty or newer

      See the documentation for ubuntu_version() for supported
      predicate syntax.

    END
  ) do |args|
    Puppet::Parser::Functions.function(:ubuntu_version)
    unless args.length == 1 and args.first.is_a? String
      raise Puppet::ParseError, 'require_ubuntu() takes a single string argument'
    end
    unless function_ubuntu_version(args)
      raise Puppet::ParseError, "Ubuntu #{args.first} required."
    end
  end
end
