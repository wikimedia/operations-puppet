begin
  require 'puppet_x/bodgit/postfix/util'
rescue LoadError
  # :nocov:
  require 'pathname'
  require Pathname.new(__FILE__).dirname + '../../' + 'puppet_x/bodgit/postfix/util'
  # :nocov:
end

Puppet::Type.newtype(:postfix_master) do
  include PuppetX::Bodgit::Postfix::Util

  @doc = 'Manages Postfix services.

The resource name can be used as a shortcut for specifying the service and
type parameters by using the form `<service>/<type>` otherwise it can be left
as a normal string.'

  ensurable

  newparam(:name) do
    desc 'The name of the service and type separated by `/`, or a unique
string.'
  end

  newparam(:service) do
    desc 'The service name.'
    isnamevar
    munge do |value|
      value.to_s
    end
  end

  newparam(:type) do
    desc 'The service type.'
    isnamevar
    newvalues('inet', 'unix', 'unix-dgram', 'fifo', 'pass')
    munge do |value|
      value.to_s
    end
  end

  def self.title_patterns
    [
      [
        %r{^(\S+)\/(\S+)$},
        [
          [:service],
          [:type],
        ],
      ],
      [
        %r{(.*)},
        [
          [:name],
        ],
      ],
    ]
  end

  newproperty(:private) do
    desc 'Whether or not access is restricted.'
    newvalues('-', 'n', 'y')
    defaultto('-')
    munge do |value|
      value.to_s
    end
  end

  newproperty(:unprivileged) do
    desc 'Whether the service runs with root privileges or not.'
    newvalues('-', 'n', 'y')
    defaultto('-')
    munge do |value|
      value.to_s
    end
  end

  newproperty(:chroot) do
    desc 'Whether the service runs chrooted.'
    newvalues('-', 'n', 'y')
    defaultto('-')
    munge do |value|
      value.to_s
    end
  end

  newproperty(:wakeup) do
    desc 'Wake up time.'
    newvalues('-', %r{^\d+[?]?$})
    defaultto('-')
    munge do |value|
      value.to_s
    end
  end

  newproperty(:limit) do
    desc 'Process limit.'
    newvalues('-', %r{^\d+$})
    defaultto('-')
    munge do |value|
      value.to_s
    end
  end

  newproperty(:command) do
    desc 'The command name and arguments.

The command to run. If the command includes any `-o` options then these
follow the same autorequire rules as for
[`postfix_main`](#native-type-postfix_main) resources with the exception that
it doesn\'t autorequire a setting that is redefined with `-o` in the same
command.

If the command uses `pipe(8)` then the value from the `user=` attribute is
parsed and any existing user or group resource will be autorequired.'

    munge do |value|
      value.to_s
    end
  end

  newparam(:target) do
    desc 'The file in which to store the services, defaults to
`/etc/postfix/master.cf`.

If a file resource exists in the catalogue for this value it will be
autorequired.'
  end

  def command_scan(command)
    command.scan(%r{-o \s+ ([^=]+) = ([^ ]+)}x)
  end

  def value_split(value)
    value.split(%r{,})
  end

  autorequire(:file) do
    autos = []
    autos << self[:target] if self[:target]
    if self[:command]
      command_scan(self[:command]).each do |_setting, value|
        values = value_split(value).map do |v|
          expand(v)
        end

        autos += file_autorequires(values)
      end
    end
    autos
  end

  autorequire(:postfix_main) do
    autos = []
    if self[:command]
      settings, values = command_scan(self[:command]).transpose
      values&.each do |value|
        value_split(value).each do |v|
          value_scan(v) do |x|
            # Add the setting unless it's been redefined in this same command
            autos << x unless settings.include?(x)
          end
        end
      end
    end
    autos
  end

  autorequire(:postfix_master) do
    autos = []
    if self[:command]
      command_scan(self[:command]).each do |setting, value|
        if %r{_service_name$}.match?(setting)
          autos << "#{value}/unix"
        end
      end
    end
    autos
  end

  autorequire(:user) do
    autos = []
    if self[:command] && self[:command] =~ %r{^pipe \s}x
      if self[:command] =~ %r{\s user = ([^: ]+)}x
        autos << Regexp.last_match(1)
      end
    end
    autos
  end

  autorequire(:group) do
    autos = []
    if self[:command] && self[:command] =~ %r{^pipe \s}x
      if self[:command] =~ %r{\s user = (?:[^:]+) : ([^ ]+)}x
        autos << Regexp.last_match(1)
      end
    end
    autos
  end
end
