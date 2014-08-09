# == Function: shell_exports
#
# Generate shell environment variable declarations out of a Puppet hash.
# The uppercased hash keys are used as the variable names, and the values
# as the variable's values.
#
module Puppet::Parser::Functions
  newfunction(
    :shell_exports,
    :type  => :rvalue,
    :arity => 1,
    :doc   => <<-END
      Generate shell environment variable declarations out of a Puppet hash.

      The uppercased hash keys are used as the variable names, and the values
      as the variable's values.

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
    vars.map { |var, value| "export #{var.upcase}=#{value.inspect}" }.push('').join("\n")
  end
end
