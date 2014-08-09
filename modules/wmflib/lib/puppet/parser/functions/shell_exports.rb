# == Function: shell_exports
#
# shell_exports(vars, uppercase_keys=true):
#
# Generate shell environment variable declarations out of a Puppet hash.
#
# The hash keys are used as the variable names, and the values as
# the variable's values. Values are automatically quoted with double
# quotes. If the second parameter is true (the default), keys are
# automatically uppercased.
#
module Puppet::Parser::Functions
  newfunction(
    :shell_exports,
    :type  => :rvalue,
    :arity => 1,
    :doc   => <<-END
      shell_exports(vars, uppercase_keys=true):

      Generate shell environment variable declarations out of a Puppet hash.

      The hash keys are used as the variable names, and the values as
      the variable's values. Values are automatically quoted with double
      quotes. If the second parameter is true (the default), keys are
      automatically uppercased.

      Example:

         shell_exports({
           apache_run_user => 'apache',
           apache_pid_file => '/var/run/apache2/apache2.pid',
         })

      Output:

         export APACHE_RUN_USER="apache"
         export APACHE_PID_FILE="/var/run/apache2/apache2.pid"

    END
  ) do |args|
    vars = args.first
    raise Puppet::ParseError, 'shell_exports() requires a hash argument' unless vars.is_a? Hash
    vars.map { |var, value| "export #{var.upcase}=#{value.to_pson}" }.push('').join("\n")
  end
end
