require 'puppet/property/ordered_list'

Puppet::Type.newtype(:host) do
  @doc = "@summary Installs and manages host entries.

      For most systems, these entries will just be in `/etc/hosts`, but some
      systems (notably OS X) will have different solutions."

  ensurable

  newproperty(:ip) do
    desc "The host's IP address, IPv4 or IPv6."

    def valid_v4?(addr)
      data = addr.match(%r{^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$})
      data && data.captures.map(&:to_i).all? { |i| i >= 0 && i <= 255 }
    end

    def valid_v6?(addr)
      # http://forums.dartware.com/viewtopic.php?t=452
      # ...and, yes, it is this hard. Doing it programmatically is harder.
      addr =~ %r{^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$}
    end

    def valid_newline?(addr)
      addr !~ %r{\n} && addr !~ %r{\r}
    end

    validate do |value|
      return true if (valid_v4?(value) || valid_v6?(value)) && valid_newline?(value)
      raise Puppet::Error, _('Invalid IP address %{value}') % { value: value.inspect }
    end
  end

  # for now we use OrderedList to indicate that the order does matter.
  newproperty(:host_aliases, parent: Puppet::Property::OrderedList) do
    desc "Any aliases the host might have.  Multiple values must be
        specified as an array."

    def delimiter
      ' '
    end

    def inclusive?
      true
    end

    validate do |value|
      # This regex already includes newline check.
      raise Puppet::Error, _('Host aliases cannot include whitespace') if %r{\s}.match?(value)
      raise Puppet::Error, _('Host aliases cannot be an empty string. Use an empty array to delete all host_aliases ') if %r{^\s*$}.match?(value)
    end
  end

  newproperty(:comment) do
    desc 'A comment that will be attached to the line with a # character.'
    validate do |value|
      if value.include?("\n") || value.include?("\r")
        raise Puppet::Error, _('Comment cannot include newline')
      end
    end
  end

  newproperty(:target) do
    desc "The file in which to store service information.  Only used by
        those providers that write to disk. On most systems this defaults to `/etc/hosts`."

    defaultto do
      if @resource.class.defaultprovider.ancestors.include?(Puppet::Provider::ParsedFile)
        @resource.class.defaultprovider.default_target
      else
        nil
      end
    end
  end

  newparam(:name) do
    desc 'The host name.'

    isnamevar

    validate do |value|
      value.split('.').each do |hostpart|
        unless %r{^([\w]+|[\w][\w\-]+[\w])$}.match?(hostpart)
          raise Puppet::Error, _('Invalid host name')
        end
      end
      if value.include?("\n") || value.include?("\r")
        raise Puppet::Error, _('Hostname cannot include newline')
      end
    end
  end
end
