require 'puppet/provider/parsedfile'

Puppet::Type.type(:ssh_authorized_key).provide(
  :parsed,
  parent: Puppet::Provider::ParsedFile,
  filetype: :flat,
  default_target: '',
) do
  desc 'Parse and generate authorized_keys files for SSH.'

  text_line :comment, match: %r{^\s*#}
  text_line :blank, match: %r{^\s*$}

  record_line :parsed,
              fields: ['options', 'type', 'key', 'name'],
              optional: ['options'],
              rts: %r{^\s+},
              match: Puppet::Type.type(:ssh_authorized_key).keyline_regex,
              post_parse: proc { |h|
                h[:name] = '' if h[:name] == :absent
                h[:options] ||= [:absent]
                h[:options] = Puppet::Type::Ssh_authorized_key::ProviderParsed.parse_options(h[:options]) if h[:options].is_a? String
              },
              pre_gen: proc { |h|
                # if this name was generated, don't write it back to disk
                h[:name] = '' if h[:unnamed]
                h[:options] = [] if h[:options].include?(:absent)
                h[:options] = h[:options].join(',')
              }

  record_line :key_v1,
              fields: ['options', 'bits', 'exponent', 'modulus', 'name'],
              optional: ['options'],
              rts: %r{^\s+},
              match: %r{^(?:(.+) )?(\d+) (\d+) (\d+)(?: (.+))?$}

  def dir_perm
    0o700
  end

  def file_perm
    0o600
  end

  def group_writable_perm
    0o020
  end

  def group_writable?(path)
    path.stat.mode & group_writable_perm != 0
  end

  def trusted_path
    # return if the parent directory does not exist
    return false unless Puppet::FileSystem.dir_exist?(target)
    path = Puppet::FileSystem.pathname(target).dirname
    until path.dirname.root?
      path = path.realpath if path.symlink?
      # do not trust if path is world or group writable
      if path.stat.uid != Process.euid || path.world_writable? || group_writable?(path)
        Puppet.debug('Path untrusted, will attempt to write as the target user')
        return false
      end
      path = path.dirname
    end
    Puppet.debug('Path trusted, writing the file as the current user')
  end

  def flush
    raise Puppet::Error, 'Cannot write SSH authorized keys without user'    unless @resource.should(:user)
    raise Puppet::Error, "User '#{@resource.should(:user)}' does not exist" unless Puppet::Util.uid(@resource.should(:user))
    # ParsedFile usually calls backup_target much later in the flush process,
    # but our SUID makes that fail to open filebucket files for writing.
    # Fortunately, there's already logic to make sure it only ever happens once,
    # so calling it here suppresses the later attempt by our superclass's flush method.
    self.class.backup_target(target)

    # attempt to create the file as the specified user if we're not dropping privileges
    if @resource[:drop_privileges]
      Puppet::Util::SUIDManager.asuser(@resource.should(:user)) do
        unless Puppet::FileSystem.exist?(dir = File.dirname(target))
          Puppet.debug "Creating #{dir} as #{@resource.should(:user)}"
          Dir.mkdir(dir, dir_perm)
        end
        super

        File.chmod(file_perm, target)
      end
    # to avoid race conditions when handling permissions as a privileged user
    # (CVE-2011-3870) we use the trusted_path method to ensure the entire
    # directory structure is "safe" to write in
    else
      raise Puppet::Error, 'drop_privileges is false but the target path is not trusted' unless trusted_path
      super

      uid = Puppet::Util.uid(@resource.should(:user))
      gid = Puppet::Util.gid(@resource.should(:user))
      File.open(target) do |target|
        target.chown(uid, gid)
        target.chmod(file_perm)
      end
    end
  end

  # Parse sshv2 option strings, which is a comma-separated list of
  # either key="values" elements or bare-word elements
  def self.parse_options(options)
    result = []
    scanner = StringScanner.new(options)
    until scanner.eos?
      scanner.skip(%r{[ \t]*})
      # scan a long option
      out = scanner.scan(%r{[-a-z0-9A-Z_]+=\".*?[^\\]\"}) || scanner.scan(%r{[-a-z0-9A-Z_]+})

      # found an unscannable token, let's abort
      break unless out

      result << out

      # eat a comma
      scanner.skip(%r{[ \t]*,[ \t]*})
    end
    result
  end

  def self.prefetch_hook(records)
    name_index = 0
    records.each do |record|
      next unless record[:record_type] == :parsed && record[:name].empty?
      record[:unnamed] = true
      # Generate a unique ID for unnamed keys, in case they need purging.
      # If you change this, you have to keep
      # Puppet::Type::User#unknown_keys_in_file in sync! (PUP-3357)
      record[:name] = "#{record[:target]}:unnamed-#{name_index += 1}"
      Puppet.debug("generating name for on-disk ssh_authorized_key #{record[:key]}: #{record[:name]}")
    end
  end
end
