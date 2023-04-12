require 'puppet/provider/parsedfile'
require_relative '../mount'

fstab = case Facter.value(:osfamily)
        when 'Solaris' then '/etc/vfstab'
        when 'AIX' then '/etc/filesystems'
        else
          '/etc/fstab'
        end

Puppet::Type.type(:mount).provide(
  :parsed,
  parent: Puppet::Provider::ParsedFile,
  default_target: fstab,
  filetype: :flat,
) do
  include Puppet::Provider::Mount

  @doc = "Installs and manages host entries.  For most systems, these
      entries will just be in `/etc/hosts`, but some systems (notably OS X)
      will have different solutions."

  commands mountcmd: 'mount', umount: 'umount'

  @fields = case Facter.value(:osfamily)
            when 'Solaris'
              [:device, :blockdevice, :name, :fstype, :pass, :atboot, :options]
            else
              [:device, :name, :fstype, :options, :dump, :pass]
            end

  if Facter.value(:osfamily) == 'AIX'
    # * is the comment character on AIX /etc/filesystems
    text_line :comment, match: %r{^\s*\*}
  else
    text_line :comment, match: %r{^\s*#}
  end
  text_line :blank, match: %r{^\s*$}

  optional_fields  = @fields - [:device, :name, :blockdevice]
  mandatory_fields = @fields - optional_fields

  # fstab will ignore lines that have fewer than the mandatory number of columns,
  # so we should, too.
  field_pattern = '(\s*(?>\S+))'
  text_line :incomplete, match: %r{^(?!#{field_pattern}{#{mandatory_fields.length}})}

  case Facter.value(:osfamily)
  when 'AIX'
    # The only field that is actually ordered is :name. See `man filesystems` on AIX
    @fields = [:name, :account, :boot, :check, :dev, :free, :mount, :nodename,
               :options, :quota, :size, :type, :vfs, :vol, :log]
    self.line_separator = "\n"
    # Override lines and use scan instead of split, because we DON'T want to
    # remove the separators
    def self.lines(text)
      lines = text.split("\n")
      filesystem_stanza = false
      filesystem_index = 0
      ret = []
      lines.each_with_index do |line, i|
        if %r{^\S+:}.match?(line)
          # Begin new filesystem stanza and save the index
          ret[filesystem_index] = filesystem_stanza.join("\n") if filesystem_stanza
          filesystem_stanza = Array(line)
          filesystem_index = i
          # Eat the preceding blank line
          ret[i - 1] = nil if i > 0 && ret[i - 1] && ret[i - 1].match(%r{^\s*$})
          nil
        elsif %r{^(\s*\*.*|\s*)$}.match?(line)
          # Just a comment or blank line; add in place
          ret[i] = line
        else
          # Non-comments or blank lines must be part of a stanza
          filesystem_stanza << line
        end
      end
      # Add the final stanza to the return
      ret[filesystem_index] = filesystem_stanza.join("\n") if filesystem_stanza
      ret = ret.compact.flatten
      ret.reject { |line| line.match(%r{^\* HEADER}) }
    end

    def self.header
      super.gsub(%r{^#}, '*')
    end

    record_line name,
                fields: @fields,
                separator: %r{\n},
                block_eval: :instance do
      def post_parse(result)
        property_map = {
          dev: :device,
          nodename: :nodename,
          options: :options,
          vfs: :fstype,
        }
        # Result is modified in-place instead of being returned; icky!
        memo = result.dup
        result.clear
        # Save the line for later, just in case it is unparsable
        result[:line] = @fields.map { |field|
          memo[field] if memo[field] != :absent
        }.compact.join("\n")
        result[:record_type] = memo[:record_type]
        special_options = []
        result[:name] = memo[:name].sub(%r{:\s*$}, '').strip
        memo.each do |_, k_v|
          next unless k_v&.is_a?(String) && k_v.match('=')
          attr_name, attr_value = k_v.split('=', 2).map(&:strip)
          attr_map_name = property_map[attr_name.to_sym]
          if attr_map_name
            # These are normal "options" options (see `man filesystems`)
            result[attr_map_name] = attr_value
          else
            # These /etc/filesystem attributes have no mount resource simile,
            # so are added to the "options" property for puppet's sake
            special_options << "#{attr_name}=#{attr_value}"
          end
          if result[:nodename]
            result[:device] = "#{result[:nodename]}:#{result[:device]}"
            result.delete(:nodename)
          end
        end
        result[:options] = [result[:options], special_options.sort].flatten.compact.join(',')
        unless result[:device]
          result[:device] = :absent
          # TRANSLATORS "prefetch" is a program name and should not be translated
          Puppet.err _("Prefetch: Mount[%{name}]: Field 'device' is missing") % { name: result[:name] }
        end
        unless result[:fstype]
          result[:fstype] = :absent
          # TRANSLATORS "prefetch" is a program name and should not be translated
          Puppet.err _("Prefetch: Mount[%{name}]: Field 'fstype' is missing") % { name: result[:name] }
        end
      end

      def to_line(result)
        output = []
        output << "#{result[:name]}:"
        if result[:device]&.match(%r{^/})
          output << "\tdev\t\t= #{result[:device]}"
        elsif result[:device] && result[:device] != :absent
          unless %r{^.+:/}.match?(result[:device])
            # Just skip this entry; it was malformed to begin with
            Puppet.err _("Mount[%{name}]: Field 'device' must be in the format of <absolute path> or <host>:<absolute path>") % { name: result[:name] }
            return result[:line]
          end
          nodename, path = result[:device].split(':')
          output << "\tdev\t\t= #{path}"
          output << "\tnodename\t= #{nodename}"
        else
          # Just skip this entry; it was malformed to begin with
          Puppet.err _("Mount[%{name}]: Field 'device' is required") % { name: result[:name] }
          return result[:line]
        end
        if result[:fstype] && result[:fstype] != :absent
          output << "\tvfs\t\t= #{result[:fstype]}"
        else
          # Just skip this entry; it was malformed to begin with
          Puppet.err _("Mount[%{name}]: Field 'device' is required") % { name: result[:name] }
          return result[:line]
        end
        if result[:options]
          options = result[:options].split(',')
          special_options = options.select do |x|
            x.match('=') &&
              ['account', 'boot', 'check', 'free', 'mount', 'size', 'type',
               'vol', 'log', 'quota'].include?(x.split('=').first)
          end
          options -= special_options
          special_options.sort.each do |x|
            k, v = x.split('=')
            output << "\t#{k}\t\t= #{v}"
          end
          output << "\toptions\t\t= #{options.join(',')}" unless options.empty?
        end
        if result[:line] && result[:line].split("\n").sort == output.sort
          "\n#{result[:line]}"
        else
          "\n#{output.join("\n")}"
        end
      end
    end
  else
    record_line name, fields: @fields, separator: %r{\s+}, joiner: "\t", optional: optional_fields, block_eval: :instance do
      def to_line(record)
        # convert whitespace to ASCII before writing to fstab
        # duplicate the record since we don't want our resource to have ASCII whitespaces
        result = record.dup
        [:device, :name].each do |param|
          if record[param].is_a?(String)
            result[param] = result[param].gsub(' ', '\\\040') if result[param].include?(' ')
          end
        end
        join(result)
      end

      def post_parse(record)
        # handle ASCII-encoded whitespaces in fstab
        [:device, :name].each do |param|
          if record[param].is_a?(String)
            record[param].gsub!('\040', ' ') if record[param].include?('\040')
          end
        end
        record
      end

      def pre_gen(record)
        if !record[:options] || record[:options].empty?
          if Facter.value(:kernel) == 'Linux'
            record[:options] = 'defaults'
          else
            raise Puppet::Error, _("Mount[%{name}]: Field 'options' is required") % { name: record[:name] }
          end
        end
        if !record[:fstype] || record[:fstype].empty?
          raise Puppet::Error, _("Mount[%{name}]: Field 'fstype' is required") % { name: record[:name] }
        end
        record
      end
    end
  end

  # Every entry in fstab is :unmounted until we can prove different
  def self.prefetch_hook(target_records)
    target_records.map do |record|
      # Eat the trailing slash(es) of mountpoints in fstab
      # This mimics the behavior of munging the resource title
      record[:name]&.gsub!(%r{^(.+?)/*$}, '\1')
      record[:ensure] = :unmounted if record[:record_type] == :parsed
      record
    end
  end

  def self.instances
    providers = super
    mounts = mountinstances.dup

    # Update fstab entries that are mounted
    providers.each do |prov|
      if mounts.delete(name: prov.get(:name), mounted: :yes)
        prov.set(ensure: :mounted)
      end
    end

    # Add mounts that are not in fstab but mounted
    mounts.each do |mount|
      providers << new(ensure: :ghost, name: mount[:name])
    end
    providers
  end

  def self.prefetch(resources = nil)
    # Get providers for all resources the user defined and that match
    # a record in /etc/fstab.
    super
    # We need to do two things now:
    # - Update ensure from :unmounted to :mounted if the resource is mounted
    # - Check for mounted devices that are not in fstab and
    #   set ensure to :ghost (if the user wants to add an entry
    #   to fstab we need to know if the device was mounted before)
    mountinstances.each do |hash|
      mount = resources[hash[:name]]
      next unless mount
      case mount.provider.get(:ensure)
      when :absent # Mount not in fstab
        mount.provider.set(ensure: :ghost)
      when :unmounted # Mount in fstab
        mount.provider.set(ensure: :mounted)
      end
    end
  end

  def self.mountinstances
    regex = case Facter.value(:osfamily)
            when 'Darwin'
              %r{ on (?:/private/var/automount)?(\S*)}
            when 'Solaris', 'HP-UX'
              %r{^(\S*) on }
            when 'AIX'
              %r{^(?:\S*\s+\S+\s+)(\S+)}
            when %r{FreeBSD|NetBSD}i
              %r{ on (.*) \(}
            else
              %r{ on (.*) type }
            end
    instances = []
    mount_output = mountcmd.split("\n")
    if mount_output.length >= 2 && mount_output[1] =~ %r{^[- \t]*$}
      # On some OSes (e.g. AIX) mount output begins with a header line
      # followed by a line consisting of dashes and whitespace.
      # Discard these two lines.
      mount_output[0..1] = []
    end
    mount_output.each do |line|
      if (match = regex.match(line)) && (name = match.captures.first)
        instances << { name: name, mounted: :yes } # Only :name is important here
      else
        raise Puppet::Error, _('Could not understand line %{line} from mount output') % { line: line }
      end
    end
    instances
  end

  def flush
    needs_mount = @property_hash.delete(:needs_mount)
    super
    mount if needs_mount
  end
end
