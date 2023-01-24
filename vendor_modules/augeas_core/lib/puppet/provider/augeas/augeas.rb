#
#   Copyright 2011 Bryan Kearney <bkearney@redhat.com>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       https://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require 'augeas' if Puppet.features.augeas?
require 'strscan'
require 'puppet/util'
require 'puppet/util/diff'
require 'puppet/util/package'
require_relative '../../../puppet_x/augeas/util/parser'

Puppet::Type.type(:augeas).provide(:augeas) do
  include Puppet::Util
  include Puppet::Util::Diff
  include Puppet::Util::Package
  include PuppetX::Augeas::Util::Parser

  confine feature: :augeas

  has_features :parse_commands, :need_to_run?, :execute_changes

  SAVE_NOOP = 'noop'.freeze
  SAVE_OVERWRITE = 'overwrite'.freeze
  SAVE_NEWFILE = 'newfile'.freeze
  SAVE_BACKUP = 'backup'.freeze

  COMMANDS = {
    'set' => [:path, :string],
    'setm' => [:path, :string, :string],
    'rm' => [:path],
    'remove' => [:path],
    'clear' => [:path],
    'clearm' => [:path, :string],
    'touch' => [:path],
    'mv' => [:path, :path],
    'move' => [:path, :path],
    'rename' => [:path, :string],
    'insert' => [:string, :string, :path],
    'ins' => [:string, :string, :path],
    'get' => [:path, :comparator, :string],
    'values' => [:path, :glob],
    'defvar' => [:string, :path],
    'defnode' => [:string, :path, :string],
    'match' => [:path, :glob],
    'size' => [:comparator, :int],
    'include' => [:string],
    'not_include' => [:string],
    '==' => [:glob],
    '!=' => [:glob],
  }.freeze

  attr_accessor :aug

  # Extracts an 2 dimensional array of commands which are in the
  # form of command path value.
  # The input can be
  # - A string with one command
  # - A string with many commands per line
  # - An array of strings.
  def parse_commands(data)
    context = resource[:context]
    # Add a trailing / if it is not there
    unless context.empty?
      context << '/' if context[-1, 1] != '/'
    end

    data = data.split($INPUT_RECORD_SEPARATOR) if data.is_a?(String)
    data = data.flatten
    args = []
    data.each do |line|
      next if line.nil?
      line.strip!
      next if line.empty?
      argline = []
      sc = StringScanner.new(line)
      cmd = sc.scan(%r{\w+|==|!=})
      formals = COMMANDS[cmd]
      raise(_('Unknown command %{cmd}') % { cmd: cmd }) unless formals
      argline << cmd
      narg = 0
      formals.each do |f|
        sc.skip(%r{\s+})
        narg += 1
        if f == :path
          start = sc.pos
          nbracket = 0
          in_single_tick = false
          in_double_tick = false
          loop do
            sc.skip(%r{([^\]\[\s\\'"]|\\.)+})
            ch = sc.getch
            nbracket += 1 if ch == '['
            nbracket -= 1 if ch == ']'
            in_single_tick = !in_single_tick if ch == "'"
            in_double_tick = !in_double_tick if ch == '"'
            raise(_('unmatched [')) if nbracket < 0
            break if (nbracket == 0 && !in_single_tick && !in_double_tick && (ch =~ %r{\s})) || sc.eos?
          end
          len = sc.pos - start
          len -= 1 unless sc.eos?
          p = sc.string[start, len]
          raise(_('missing path argument %{narg} for %{cmd}') % { narg: narg, cmd: cmd }) if p.nil?

          # Rip off any ticks if they are there.
          p = p[1, (p.size - 2)] if p[0, 1] == "'" || p[0, 1] == '"'
          p.chomp!('/')
          argline << if p[0, 1] != '$' && p[0, 1] != '/'
                       context + p
                     else
                       p
                     end
        elsif f == :string
          delim = sc.peek(1)
          if ["'", '"'].include?(delim)
            sc.getch
            argline << sc.scan(%r{([^\\#{delim}]|(\\.))*})
            # Unescape the delimiter so it's actually possible to have a
            # literal delim inside the string. We only unescape the
            # delimeter and not every backslash-escaped character so that
            # things like escaped spaces '\ ' get passed through because
            # Augeas needs to see them. If we unescaped them, too, users
            # would be forced to double-escape them
            argline.last.gsub!(%r{\\(#{delim})}, '\1')
            sc.getch
          else
            argline << sc.scan(%r{[^\s]+})
          end
          raise(_('missing string argument %{narg} for %{cmd}') % { narg: narg, cmd: cmd }) unless argline[-1]
        elsif f == :comparator
          argline << sc.scan(%r{(==|!=|=~|<=|>=|<|>)})
          unless argline[-1]
            puts sc.rest
            raise(_('invalid comparator for command %{cmd}') % { cmd: cmd })
          end
        elsif f == :int
          argline << sc.scan(%r{\d+}).to_i
        elsif f == :glob
          argline << sc.rest
        end
      end
      args << argline
    end
    args
  end

  def open_augeas
    unless @aug
      flags = Augeas::NONE
      flags = Augeas::TYPE_CHECK if resource[:type_check] == :true

      flags |= if resource[:incl]
                 Augeas::NO_MODL_AUTOLOAD
               else
                 Augeas::NO_LOAD
               end

      root = resource[:root]
      load_path = get_load_path(resource)
      debug("Opening augeas with root #{root}, lens path #{load_path}, flags #{flags}")
      @aug = Augeas.open(root, load_path, flags)

      debug("Augeas version #{get_augeas_version} is installed") if versioncmp(get_augeas_version, '0.3.6') >= 0

      # Optimize loading if the context is given and it's a simple path,
      # requires the glob function from Augeas 0.8.2 or up
      glob_avail = !aug.match('/augeas/version/pathx/functions/glob').empty?
      opt_ctx = resource[:context].match("^/files/[^'\"\\[\\]]+$") if resource[:context]

      if resource[:incl]
        aug.set('/augeas/load/Xfm/lens', resource[:lens])
        aug.set('/augeas/load/Xfm/incl', resource[:incl])
        restricted_metadata = '/augeas//error'
      elsif glob_avail && opt_ctx
        # Optimize loading if the context is given, requires the glob function
        # from Augeas 0.8.2 or up
        ctx_path = resource[:context].sub(%r{^/files(.*?)/?$}, '\1/')
        load_path = "/augeas/load/*['%s' !~ glob(incl) + regexp('/.*')]" % ctx_path

        if aug.match(load_path).size < aug.match('/augeas/load/*').size
          aug.rm(load_path)
          restricted_metadata = "/augeas/files#{ctx_path}/error"
        else
          # This will occur if the context is less specific than any glob
          debug('Unable to optimize files loaded by context path, no glob matches')
        end
      end
      aug.load
      print_load_errors(restricted_metadata)
    end
    @aug
  end

  def close_augeas
    return if @aug.nil?

    @aug.close
    debug('Closed the augeas connection')
    @aug = nil
  end

  def numeric?(s)
    case s
    when Integer
      true
    when String
      s.match(%r{\A[+-]?\d+?(\.\d+)?\Z}n).nil? ? false : true
    else
      false
    end
  end

  # Used by the need_to_run? method to process get filters. Returns
  # true if there is a match, false if otherwise
  # Assumes a syntax of get /files/path [COMPARATOR] value
  def process_get(cmd_array)
    return_value = false

    # validate and tear apart the command
    raise(_('Invalid command: %{cmd}') % { cmd: cmd_array.join(' ') }) if cmd_array.length < 4
    _ = cmd_array.shift
    path = cmd_array.shift
    comparator = cmd_array.shift
    arg = cmd_array.join(' ')

    # check the value in augeas
    result = @aug.get(path) || ''

    if ['<', '<=', '>=', '>'].include?(comparator) && numeric?(result) &&
       numeric?(arg)
      resultf = result.to_f
      argf = arg.to_f
      return_value = resultf.send(comparator, argf)
    elsif comparator == '!='
      return_value = (result != arg)
    elsif comparator == '=~'
      regex = Regexp.new(arg)
      return_value = (result =~ regex)
    else
      return_value = result.send(comparator, arg)
    end
    !!return_value
  end

  # Used by the need_to_run? method to process values filters. Returns
  # true if there is a matched value, false if otherwise
  def process_values(cmd_array)
    return_value = false

    # validate and tear apart the command
    raise(_('Invalid command: %{cmd}') % { cmd: cmd_array.join(' ') }) if cmd_array.length < 3
    _ = cmd_array.shift
    path = cmd_array.shift

    # Need to break apart the clause
    clause_array = parse_commands(cmd_array.shift)[0]
    verb = clause_array.shift

    # Get the match paths from augeas
    result = @aug.match(path) || []
    raise(_("Error trying to get path '%{path}'") % { path: path }) if result == -1

    # Get the values of the match paths from augeas
    values = result.map { |r| @aug.get(r) }

    case verb
    when 'include'
      arg = clause_array.shift
      return_value = values.include?(arg)
    when 'not_include'
      arg = clause_array.shift
      return_value = !values.include?(arg)
    when '=='
      begin
        arg = clause_array.shift
        new_array = parse_to_array(arg)
        return_value = (values == new_array)
      rescue
        raise(_('Invalid array in command: %{cmd}') % { cmd: cmd_array.join(' ') })
      end
    when '!='
      begin
        arg = clause_array.shift
        new_array = parse_to_array(arg)
        return_value = (values != new_array)
      rescue
        raise(_('Invalid array in command: %{cmd}') % { cmd: cmd_array.join(' ') })
      end
    end
    !!return_value
  end

  # Used by the need_to_run? method to process match filters. Returns
  # true if there is a match, false if otherwise
  def process_match(cmd_array)
    return_value = false

    # validate and tear apart the command
    raise(_('Invalid command: %{cmd}') % { cmd: cmd_array.join(' ') }) if cmd_array.length < 3
    _ = cmd_array.shift
    path = cmd_array.shift

    # Need to break apart the clause
    clause_array = parse_commands(cmd_array.shift)[0]
    verb = clause_array.shift

    # Get the values from augeas
    result = @aug.match(path) || []
    raise(_("Error trying to match path '%{path}'") % { path: path }) if result == -1

    # Now do the work
    case verb
    when 'size'
      raise(_('Invalid command: %{cmd}') % { cmd: cmd_array.join(' ') }) if clause_array.length != 2
      comparator = clause_array.shift
      arg = clause_array.shift
      return_value = case comparator
                     when '!='
                       !result.size.send(:==, arg)
                     else
                       result.size.send(comparator, arg)
                     end
    when 'include'
      arg = clause_array.shift
      return_value = result.include?(arg)
    when 'not_include'
      arg = clause_array.shift
      return_value = !result.include?(arg)
    when '=='
      begin
        arg = clause_array.shift
        new_array = parse_to_array(arg)
        return_value = (result == new_array)
      rescue
        raise(_('Invalid array in command: %{cmd}') % { cmd: cmd_array.join(' ') })
      end
    when '!='
      begin
        arg = clause_array.shift
        new_array = parse_to_array(arg)
        return_value = (result != new_array)
      rescue
        raise(_('Invalid array in command: %{cmd}') % { cmd: cmd_array.join(' ') })
      end
    end
    !!return_value
  end

  # Generate lens load paths from user given paths and local pluginsync dir
  def get_load_path(resource)
    load_path = []

    # Permits colon separated strings or arrays
    if resource[:load_path]
      load_path = [resource[:load_path]].flatten
      load_path.map! { |path| path.split(%r{:}) }
      load_path.flatten!
    end

    if Puppet.run_mode.name == :agent
      if Puppet::FileSystem.exist?("#{Puppet[:libdir]}/augeas/lenses")
        load_path << "#{Puppet[:libdir]}/augeas/lenses"
      end
    else
      env = Puppet.lookup(:current_environment)
      env.each_plugin_directory do |dir|
        lenses = File.join(dir, 'augeas', 'lenses')
        if File.exist?(lenses)
          load_path << lenses
        end
      end
    end

    load_path.join(':')
  end

  def get_augeas_version
    @aug.get('/augeas/version') || ''
  end

  def set_augeas_save_mode(mode)
    @aug.set('/augeas/save', mode)
  end

  def print_load_errors(path)
    errors = @aug.match('/augeas//error')
    unless errors.empty?
      if path && !@aug.match(path).empty?
        warning(_('Loading failed for one or more files, see debug for /augeas//error output'))
      else
        debug('Loading failed for one or more files, output from /augeas//error:')
      end
    end
    print_errors(errors)
  end

  def print_put_errors
    errors = @aug.match("/augeas//error[. = 'put_failed']")
    debug('Put failed on one or more files, output from /augeas//error:') unless errors.empty?
    print_errors(errors)
  end

  def print_errors(errors)
    errors.each do |errnode|
      error = @aug.get(errnode)
      debug("#{errnode} = #{error}") unless error.nil?
      @aug.match("#{errnode}/*").each do |subnode|
        subvalue = @aug.get(subnode)
        debug("#{subnode} = #{subvalue}")
      end
    end
  end

  # Determines if augeas actually needs to run.
  def need_to_run?
    force = resource[:force]
    return_value = true
    begin
      open_augeas
      filter = resource[:onlyif]
      unless filter == ''
        cmd_array = parse_commands(filter)[0]
        command = cmd_array[0]
        begin
          case command
          when 'get' then return_value = process_get(cmd_array)
          when 'values' then return_value = process_values(cmd_array)
          when 'match' then return_value = process_match(cmd_array)
          end
        rescue StandardError => e
          raise(_("Error sending command '%{command}' with params %{param}/%{message}") % { command: command, param: cmd_array[1..-1].inspect, message: e.message })
        end
      end

      unless force
        # If we have a version of augeas which is at least 0.3.6 then we
        # can make the changes now and see if changes were made.
        if return_value && versioncmp(get_augeas_version, '0.3.6') >= 0
          debug('Will attempt to save and only run if files changed')
          # Execute in NEWFILE mode so we can show a diff
          set_augeas_save_mode(SAVE_NEWFILE)
          do_execute_changes
          save_result = @aug.save
          unless save_result
            print_put_errors
            raise(Puppet::Error, _('Save failed, see debug output for details'))
          end

          saved_files = @aug.match('/augeas/events/saved')
          if !saved_files.empty?
            root = resource[:root].sub(%r{^/$}, '')
            saved_files.map! { |key| @aug.get(key).sub(%r{^/files}, root) }
            saved_files.uniq.each do |saved_file|
              if Puppet[:show_diff] && @resource[:show_diff]
                send(@resource[:loglevel], "\n" + diff(saved_file, saved_file + '.augnew'))
              end
              File.delete(saved_file + '.augnew')
            end
            debug('Files changed, should execute')
            return_value = true
          else
            debug('Skipping because no files were changed')
            return_value = false
          end
        end
      end
    ensure
      if !return_value || resource.noop? || !save_result
        close_augeas
      end
    end
    return_value
  end

  def execute_changes
    # Workaround Augeas bug where changing the save mode doesn't trigger a
    # reload of the previously saved file(s) when we call Augeas#load
    @aug.match('/augeas/events/saved').each do |file|
      @aug.rm("/augeas#{@aug.get(file)}/mtime")
    end

    # Reload augeas, and execute the changes for real
    set_augeas_save_mode(SAVE_OVERWRITE) if versioncmp(get_augeas_version, '0.3.6') >= 0
    @aug.load
    do_execute_changes
    unless @aug.save
      print_put_errors
      raise(Puppet::Error, _('Save failed, see debug output for details'))
    end

    :executed
  ensure
    close_augeas
  end

  # Actually execute the augeas changes.
  # rubocop:disable Style/GuardClause
  def do_execute_changes
    commands = parse_commands(resource[:changes])
    commands.each do |cmd_array|
      raise(_('invalid command %{cmd}') % { value0: cmd_array.join[' '] }) if cmd_array.length < 2
      command = cmd_array[0]
      cmd_array.shift
      begin
        case command
        when 'set'
          debug("sending command '#{command}' with params #{cmd_array.inspect}")
          rv = aug.set(cmd_array[0], cmd_array[1])
          raise(_("Error sending command '%{command}' with params %{params}") % { command: command, params: cmd_array.inspect }) unless rv
        when 'setm'
          if aug.respond_to?(command)
            debug("sending command '#{command}' with params #{cmd_array.inspect}")
            rv = aug.setm(cmd_array[0], cmd_array[1], cmd_array[2])
            raise(_("Error sending command '%{command}' with params %{params}") % { command: command, params: cmd_array.inspect }) if rv == -1
          else
            raise(_("command '%{command}' not supported in installed version of ruby-augeas") % { command: command })
          end
        when 'rm', 'remove'
          debug("sending command '#{command}' with params #{cmd_array.inspect}")
          rv = aug.rm(cmd_array[0])
          raise(_("Error sending command '%{command}' with params %{params}") % { command: command, params: cmd_array.inspect }) if rv == -1
        when 'clear'
          debug("sending command '#{command}' with params #{cmd_array.inspect}")
          rv = aug.clear(cmd_array[0])
          raise(_("Error sending command '%{command}' with params %{params}") % { command: command, params: cmd_array.inspect }) unless rv
        when 'clearm'
          # Check command exists ... doesn't currently in ruby-augeas 0.4.1
          if aug.respond_to?(command)
            debug("sending command '#{command}' with params #{cmd_array.inspect}")
            rv = aug.clearm(cmd_array[0], cmd_array[1])
            raise(_("Error sending command '%{command}' with params %{params}") % { command: command, params: cmd_array.inspect }) unless rv
          else
            raise(_("command '%{command}' not supported in installed version of ruby-augeas") % { command: command })
          end
        when 'touch'
          debug("sending command '#{command}' (match, set) with params #{cmd_array.inspect}")
          if aug.match(cmd_array[0]).empty?
            rv = aug.clear(cmd_array[0])
            raise(_("Error sending command '%{command}' with params %{params}") % { command: command, params: cmd_array.inspect }) unless rv
          end
        when 'insert', 'ins'
          label = cmd_array[0]
          where = cmd_array[1]
          path = cmd_array[2]
          case where
          when 'before' then before = true
          when 'after' then before = false
          else raise(_("Invalid value '%{where}' for where param") % { where: where })
          end
          debug("sending command '#{command}' with params #{[label, where, path].inspect}")
          rv = aug.insert(path, label, before)
          raise(_("Error sending command '%{command}' with params %{params}") % { command: command, params: cmd_array.inspect }) if rv == -1
        when 'defvar'
          debug("sending command '#{command}' with params #{cmd_array.inspect}")
          rv = aug.defvar(cmd_array[0], cmd_array[1])
          raise(_("Error sending command '%{command}' with params %{params}") % { command: command, params: cmd_array.inspect }) unless rv
        when 'defnode'
          debug("sending command '#{command}' with params #{cmd_array.inspect}")
          rv = aug.defnode(cmd_array[0], cmd_array[1], cmd_array[2])
          raise(_("Error sending command '%{command}' with params %{params}") % { command: command, params: cmd_array.inspect }) unless rv
        when 'mv', 'move'
          debug("sending command '#{command}' with params #{cmd_array.inspect}")
          rv = aug.mv(cmd_array[0], cmd_array[1])
          raise(_("Error sending command '%{command}' with params %{params}") % { command: command, params: cmd_array.inspect }) if rv == -1
        when 'rename'
          debug("sending command '#{command}' with params #{cmd_array.inspect}")
          rv = aug.rename(cmd_array[0], cmd_array[1])
          raise(_("Error sending command '%{command}' with params %{params}") % { command: command, params: cmd_array.inspect }) if rv == -1
        else raise(_("Command '%{command}' is not supported") % { command: command })
        end
      rescue StandardError => e
        raise(_("Error sending command '%{command}' with params %{params}/%{message}") % { command: command, params: cmd_array.inspect, message: e.message })
      end
    end
  end
  # rubocop:enable Style/GuardClause
end
