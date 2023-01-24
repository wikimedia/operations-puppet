require 'spec_helper'
require 'puppet/util/package'

describe Puppet::Type.type(:augeas).provider(:augeas) do
  let(:resource) do
    Puppet::Type.type(:augeas).new(
      name: 'test',
      root: my_fixture_dir,
      provider: :augeas,
    )
  end

  let(:provider) do
    resource.provider
  end

  let(:logs) do
    # rubocop:disable RSpec/InstanceVariable
    @logs
    # rubocop:enable RSpec/InstanceVariable
  end

  after(:each) do
    provider.close_augeas
  end

  def my_fixture_dir
    File.expand_path(File.join(File.dirname(__FILE__), '../../../fixtures/unit/provider/augeas/augeas'))
  end

  def tmpfile(name)
    Puppet::FileSystem.expand_path(make_tmpname(name, nil).encode(Encoding::UTF_8), Dir.tmpdir)
  end

  # Copied from ruby 2.4 source
  def make_tmpname((prefix, suffix), n)
    prefix = (String.try_convert(prefix) ||
              raise(ArgumentError, "unexpected prefix: #{prefix.inspect}"))
    suffix &&= (String.try_convert(suffix) ||
                raise(ArgumentError, "unexpected suffix: #{suffix.inspect}"))
    t = Time.now.strftime('%Y%m%d')
    path = "#{prefix}#{t}-#{$PROCESS_ID}-#{rand(0x100000000).to_s(36)}".dup
    path << "-#{n}" if n
    path << suffix if suffix
    path
  end

  describe 'command parsing' do
    it 'ignores nil values when parsing commands' do
      commands = [nil, 'set Jar/Jar Binks']
      tokens = provider.parse_commands(commands)
      expect(tokens.size).to eq(1)
      expect(tokens[0].size).to eq(3)
      expect(tokens[0][0]).to eq('set')
      expect(tokens[0][1]).to eq('Jar/Jar')
      expect(tokens[0][2]).to eq('Binks')
    end

    it 'breaks apart a single line into three tokens and clean up the context' do
      resource[:context] = '/context'
      tokens = provider.parse_commands('set Jar/Jar Binks')
      expect(tokens.size).to eq(1)
      expect(tokens[0].size).to eq(3)
      expect(tokens[0][0]).to eq('set')
      expect(tokens[0][1]).to eq('/context/Jar/Jar')
      expect(tokens[0][2]).to eq('Binks')
    end

    it 'breaks apart a multiple line into six tokens' do
      tokens = provider.parse_commands("set /Jar/Jar Binks\nrm anakin")
      expect(tokens.size).to eq(2)
      expect(tokens[0].size).to eq(3)
      expect(tokens[1].size).to eq(2)
      expect(tokens[0][0]).to eq('set')
      expect(tokens[0][1]).to eq('/Jar/Jar')
      expect(tokens[0][2]).to eq('Binks')
      expect(tokens[1][0]).to eq('rm')
      expect(tokens[1][1]).to eq('anakin')
    end

    it 'strips whitespace and ignore blank lines' do
      tokens = provider.parse_commands("  set /Jar/Jar Binks \t\n  \n\n  rm anakin ")
      expect(tokens.size).to eq(2)
      expect(tokens[0].size).to eq(3)
      expect(tokens[1].size).to eq(2)
      expect(tokens[0][0]).to eq('set')
      expect(tokens[0][1]).to eq('/Jar/Jar')
      expect(tokens[0][2]).to eq('Binks')
      expect(tokens[1][0]).to eq('rm')
      expect(tokens[1][1]).to eq('anakin')
    end

    it 'handles arrays' do
      resource[:context] = '/foo/'
      commands = ['set /Jar/Jar Binks', 'rm anakin']
      tokens = provider.parse_commands(commands)
      expect(tokens.size).to eq(2)
      expect(tokens[0].size).to eq(3)
      expect(tokens[1].size).to eq(2)
      expect(tokens[0][0]).to eq('set')
      expect(tokens[0][1]).to eq('/Jar/Jar')
      expect(tokens[0][2]).to eq('Binks')
      expect(tokens[1][0]).to eq('rm')
      expect(tokens[1][1]).to eq('/foo/anakin')
    end

    # This is not supported in the new parsing class
    # it "should concat the last values" do
    #    provider = provider_class.new
    #    tokens = provider.parse_commands("set /Jar/Jar Binks is my copilot")
    #    tokens.size.should == 1
    #    tokens[0].size.should == 3
    #    tokens[0][0].should == "set"
    #    tokens[0][1].should == "/Jar/Jar"
    #    tokens[0][2].should == "Binks is my copilot"
    # end

    it 'accepts spaces in the value and single ticks' do
      resource[:context] = '/foo/'
      tokens = provider.parse_commands("set JarJar 'Binks is my copilot'")
      expect(tokens.size).to eq(1)
      expect(tokens[0].size).to eq(3)
      expect(tokens[0][0]).to eq('set')
      expect(tokens[0][1]).to eq('/foo/JarJar')
      expect(tokens[0][2]).to eq('Binks is my copilot')
    end

    it 'accepts spaces in the value and double ticks' do
      resource[:context] = '/foo/'
      tokens = provider.parse_commands('set /JarJar "Binks is my copilot"')
      expect(tokens.size).to eq(1)
      expect(tokens[0].size).to eq(3)
      expect(tokens[0][0]).to eq('set')
      expect(tokens[0][1]).to eq('/JarJar')
      expect(tokens[0][2]).to eq('Binks is my copilot')
    end

    it 'accepts mixed ticks' do
      resource[:context] = '/foo/'
      tokens = provider.parse_commands('set JarJar "Some \'Test\'"')
      expect(tokens.size).to eq(1)
      expect(tokens[0].size).to eq(3)
      expect(tokens[0][0]).to eq('set')
      expect(tokens[0][1]).to eq('/foo/JarJar')
      expect(tokens[0][2]).to eq("Some \'Test\'")
    end

    it 'handles predicates with literals' do
      resource[:context] = '/foo/'
      tokens = provider.parse_commands("rm */*[module='pam_console.so']")
      expect(tokens).to eq([['rm', "/foo/*/*[module='pam_console.so']"]])
    end

    it 'handles whitespace in predicates' do
      resource[:context] = '/foo/'
      tokens = provider.parse_commands("ins 42 before /files/etc/hosts/*/ipaddr[ . = '127.0.0.1' ]")
      expect(tokens).to eq([['ins', '42', 'before', "/files/etc/hosts/*/ipaddr[ . = '127.0.0.1' ]"]])
    end

    it 'handles multiple predicates' do
      resource[:context] = '/foo/'
      tokens = provider.parse_commands("clear pam.d/*/*[module = 'system-auth'][type = 'account']")
      expect(tokens).to eq([['clear', "/foo/pam.d/*/*[module = 'system-auth'][type = 'account']"]])
    end

    it 'handles nested predicates' do
      resource[:context] = '/foo/'
      args = ['clear', "/foo/pam.d/*/*[module[ ../type = 'type] = 'system-auth'][type[last()] = 'account']"]
      tokens = provider.parse_commands(args.join(' '))
      expect(tokens).to eq([args])
    end

    it 'handles escaped doublequotes in doublequoted string' do
      resource[:context] = '/foo/'
      tokens = provider.parse_commands("set /foo \"''\\\"''\"")
      expect(tokens).to eq([['set', '/foo', "''\"''"]])
    end

    it 'preserves escaped single quotes in double quoted strings' do
      resource[:context] = '/foo/'
      tokens = provider.parse_commands("set /foo \"\\'\"")
      expect(tokens).to eq([['set', '/foo', "\\'"]])
    end

    it 'allows escaped spaces and brackets in paths' do
      resource[:context] = '/foo/'
      args = ['set', '/white\\ space/\\[section', 'value']
      tokens = provider.parse_commands(args.join(" \t "))
      expect(tokens).to eq([args])
    end

    it 'allows single quoted escaped spaces in paths' do
      resource[:context] = '/foo/'
      args = ['set', "'/white\\ space/key'", 'value']
      tokens = provider.parse_commands(args.join(" \t "))
      expect(tokens).to eq([['set', '/white\\ space/key', 'value']])
    end

    it 'allows double quoted escaped spaces in paths' do
      resource[:context] = '/foo/'
      args = ['set', '"/white\\ space/key"', 'value']
      tokens = provider.parse_commands(args.join(" \t "))
      expect(tokens).to eq([['set', '/white\\ space/key', 'value']])
    end

    it 'removes trailing slashes' do
      resource[:context] = '/foo/'
      tokens = provider.parse_commands('set foo/ bar')
      expect(tokens).to eq([['set', '/foo/foo', 'bar']])
    end
  end

  describe 'get filters' do
    let(:augeas) { instance_double('Augeas', get: 'value') }

    before(:each) do
      allow(augeas).to receive('close')
      provider.aug = augeas
    end

    it 'returns false for a = nonmatch' do
      command = ['get', 'fake value', '==', 'value']
      expect(provider.process_get(command)).to eq(true)
    end

    it 'returns true for a != match' do
      command = ['get', 'fake value', '!=', 'value']
      expect(provider.process_get(command)).to eq(false)
    end

    it 'returns true for a =~ match' do
      command = ['get', 'fake value', '=~', 'val*']
      expect(provider.process_get(command)).to eq(true)
    end

    it 'returns false for a == nonmatch' do
      command = ['get', 'fake value', '=~', 'num*']
      expect(provider.process_get(command)).to eq(false)
    end
  end

  describe 'values filters' do
    let(:augeas) { instance_double('Augeas', match: ['set', 'of', 'values']) }

    before(:each) do
      allow(augeas).to receive(:get).and_return('set', 'of', 'values')
      allow(augeas).to receive('close')
      provider.aug = augeas
    end

    it 'returns true for includes match' do
      command = ['values', 'fake value', 'include values']
      expect(provider.process_values(command)).to eq(true)
    end

    it 'returns false for includes non match' do
      command = ['values', 'fake value', 'include JarJar']
      expect(provider.process_values(command)).to eq(false)
    end

    it 'returns true for not_include non match' do
      command = ['values', 'fake value', 'not_include JarJar']
      expect(provider.process_values(command)).to eq(true)
    end

    it 'returns false for non_include match' do
      command = ['values', 'fake value', 'not_include values']
      expect(provider.process_values(command)).to eq(false)
    end

    it 'returns true for an array match' do
      command = ['values', 'fake value', "== ['set', 'of', 'values']"]
      expect(provider.process_values(command)).to eq(true)
    end
    it 'returns true for an array match with double quotes and spaces' do
      command = ['values', 'fake value', '==   [  "set"  ,  "of" , "values"  ]  ']
      expect(provider.process_values(command)).to eq(true)
    end

    it 'returns true for an array match with internally escaped single quotes' do
      allow(provider.aug).to receive(:match).and_return(['set', "o'values", 'here'])
      allow(provider.aug).to receive(:get).and_return('set', "o'values", 'here')
      command = ['values', 'fake value', "== [ 'set', 'o\\'values', 'here']"]
      expect(provider.process_values(command)).to eq(true)
    end

    it 'returns true for an array match with octal character sequences' do
      command = ['values', 'fake value', '== ["\\x73et", "of", "values"]']
      expect(provider.process_values(command)).to eq(true)
    end

    it 'returns true for an array match with hex character sequences' do
      command = ['values', 'fake value', '== ["\\163et", "of", "values"]']
      expect(provider.process_values(command)).to eq(true)
    end

    it 'returns true for an array match with short unicode escape sequences' do
      command = ['values', 'fake value', '== ["\\u0073et", "of", "values"]']
      expect(provider.process_values(command)).to eq(true)
    end

    it 'returns true for an array match with single character long unicode escape sequences' do
      command = ['values', 'fake value', '== ["\\u{0073}et", "of", "values"]']
      expect(provider.process_values(command)).to eq(true)
    end

    it 'returns true for an array match with multi-character long unicode escape sequences' do
      command = ['values', 'fake value', '== ["\\u{0073 0065 0074}", "of", "values"]']
      expect(provider.process_values(command)).to eq(true)
    end

    it 'returns true for an array match with literal backslashes' do
      allow(provider.aug).to receive(:match).and_return(['set', 'o\\values', 'here'])
      allow(provider.aug).to receive(:get).and_return('set', 'o\\values', 'here')
      command = ['values', 'fake value', '== [ "set", "o\\\\values", "here"]']
      expect(provider.process_values(command)).to eq(true)
    end

    it 'returns false for an array non match' do
      command = ['values', 'fake value', "== ['this', 'should', 'not', 'match']"]
      expect(provider.process_values(command)).to eq(false)
    end

    it 'returns false for an array match with noteq' do
      command = ['values', 'fake value', "!= ['set', 'of', 'values']"]
      expect(provider.process_values(command)).to eq(false)
    end

    it 'returns true for an array non match with noteq' do
      command = ['values', 'fake value', "!= ['this', 'should', 'not', 'match']"]
      expect(provider.process_values(command)).to eq(true)
    end

    it 'returns true for an array non match with double quotes and spaces' do
      command = ['values', 'fake value', '!=   [  "this"  ,  "should" ,"not",  "match"  ]  ']
      expect(provider.process_values(command)).to eq(true)
    end

    it 'returns true for an empty array match' do
      allow(provider.aug).to receive(:match).and_return([])
      allow(provider.aug).to receive(:get)
      command = ['values', 'fake value', '== []']
      expect(provider.process_values(command)).to eq(true)
    end
  end

  describe 'match filters' do
    let(:augeas) { instance_double('Augeas', match: ['set', 'of', 'values']) }

    before(:each) do
      allow(augeas).to receive('close')
      provider.aug = augeas
    end

    it 'returns true for size match' do
      command = ['match', 'fake value', 'size == 3']
      expect(provider.process_match(command)).to eq(true)
    end

    it 'returns false for a size non match' do
      command = ['match', 'fake value', 'size < 3']
      expect(provider.process_match(command)).to eq(false)
    end

    it 'returns true for includes match' do
      command = ['match', 'fake value', 'include values']
      expect(provider.process_match(command)).to eq(true)
    end

    it 'returns false for includes non match' do
      command = ['match', 'fake value', 'include JarJar']
      expect(provider.process_match(command)).to eq(false)
    end

    it 'returns true for not_includes non match' do
      command = ['match', 'fake value', 'not_include JarJar']
      expect(provider.process_match(command)).to eq(true)
    end

    it 'returns false for not_includes match' do
      command = ['match', 'fake value', 'not_include values']
      expect(provider.process_match(command)).to eq(false)
    end

    it 'returns true for an array match' do
      command = ['match', 'fake value', "== ['set', 'of', 'values']"]
      expect(provider.process_match(command)).to eq(true)
    end

    it 'returns true for an array match with double quotes and spaces' do
      command = ['match', 'fake value', '==   [  "set"  ,  "of" , "values"  ]  ']
      expect(provider.process_match(command)).to eq(true)
    end

    it 'returns false for an array non match' do
      command = ['match', 'fake value', "== ['this', 'should', 'not', 'match']"]
      expect(provider.process_match(command)).to eq(false)
    end

    it 'returns false for an array match with noteq' do
      command = ['match', 'fake value', "!= ['set', 'of', 'values']"]
      expect(provider.process_match(command)).to eq(false)
    end

    it 'returns true for an array non match with noteq' do
      command = ['match', 'fake value', "!= ['this', 'should', 'not', 'match']"]
      expect(provider.process_match(command)).to eq(true)
    end

    it 'returns true for an array non match with double quotes and spaces' do
      command = ['match', 'fake value', '!=   [  "this"  ,  "should" ,"not",  "match"  ]  ']
      expect(provider.process_match(command)).to eq(true)
    end
  end

  describe 'need to run' do
    let(:augeas) { instance_double('Augeas') }

    before(:each) do
      allow(augeas).to receive('close')
      provider.aug = augeas

      # These tests pretend to be an earlier version so the provider doesn't
      # attempt to make the change in the need_to_run? method
      allow(provider).to receive(:get_augeas_version).and_return('0.3.5')
    end

    it 'handles no filters' do
      allow(augeas).to receive('match').and_return(['set', 'of', 'values'])
      expect(provider.need_to_run?).to eq(true)
    end

    it 'returns true when a get filter matches' do
      resource[:onlyif] = 'get path == value'
      allow(augeas).to receive('get').and_return('value')
      expect(provider.need_to_run?).to eq(true)
    end

    describe 'performing numeric comparisons (#22617)' do
      it 'returns true when a get string compare is true' do
        resource[:onlyif] = 'get bpath > a'
        allow(augeas).to receive('get').and_return('b')
        expect(provider.need_to_run?).to eq(true)
      end

      it 'returns false when a get string compare is false' do
        resource[:onlyif] = 'get a19path > a2'
        allow(augeas).to receive('get').and_return('a19')
        expect(provider.need_to_run?).to eq(false)
      end

      it 'returns true when a get int gt compare is true' do
        resource[:onlyif] = 'get path19 > 2'
        allow(augeas).to receive('get').and_return('19')
        expect(provider.need_to_run?).to eq(true)
      end

      it 'returns true when a get int ge compare is true' do
        resource[:onlyif] = 'get path19 >= 2'
        allow(augeas).to receive('get').and_return('19')
        expect(provider.need_to_run?).to eq(true)
      end

      it 'returns true when a get int lt compare is true' do
        resource[:onlyif] = 'get path2 < 19'
        allow(augeas).to receive('get').and_return('2')
        expect(provider.need_to_run?).to eq(true)
      end

      it 'returns false when a get int le compare is false' do
        resource[:onlyif] = 'get path39 <= 4'
        allow(augeas).to receive('get').and_return('39')
        expect(provider.need_to_run?).to eq(false)
      end
    end
    describe 'performing is_numeric checks (#22617)' do
      it 'returns false for nil' do
        expect(provider.numeric?(nil)).to eq(false)
      end
      it 'returns true for Integers' do
        expect(provider.numeric?(9)).to eq(true)
      end
      it 'returns true for numbers in Strings' do
        expect(provider.numeric?('9')).to eq(true)
      end
      it 'returns false for non-number Strings' do
        expect(provider.numeric?('x9')).to eq(false)
      end
      it 'returns false for other types' do
        expect(provider.numeric?([true])).to eq(false)
      end
    end

    it 'returns false when a get filter does not match' do
      resource[:onlyif] = 'get path == another value'
      allow(augeas).to receive('get').and_return('value')
      expect(provider.need_to_run?).to eq(false)
    end

    it 'returns true when a match filter matches' do
      resource[:onlyif] = 'match path size == 3'
      allow(augeas).to receive('match').and_return(['set', 'of', 'values'])
      expect(provider.need_to_run?).to eq(true)
    end

    it 'returns false when a match filter does not match' do
      resource[:onlyif] = 'match path size == 2'
      allow(augeas).to receive('match').and_return(['set', 'of', 'values'])
      expect(provider.need_to_run?).to eq(false)
    end

    # Now setting force to true
    it 'setting force should not change the above logic' do
      resource[:force] = true
      resource[:onlyif] = 'match path size == 2'
      allow(augeas).to receive('match').and_return(['set', 'of', 'values'])
      expect(provider.need_to_run?).to eq(false)
    end

    # Ticket 5211 testing
    it 'returns true when a size != the provided value' do
      resource[:onlyif] = 'match path size != 17'
      allow(augeas).to receive('match').and_return(['set', 'of', 'values'])
      expect(provider.need_to_run?).to eq(true)
    end

    # Ticket 5211 testing
    it 'returns false when a size does equal the provided value' do
      resource[:onlyif] = 'match path size != 3'
      allow(augeas).to receive('match').and_return(['set', 'of', 'values'])
      expect(provider.need_to_run?).to eq(false)
    end

    [true, false].product([true, false]) do |cfg, param|
      describe "and Puppet[:show_diff] is #{cfg} and show_diff => #{param}" do
        let(:file) { '/some/random/file' }

        before(:each) do
          Puppet[:show_diff] = cfg
          resource[:show_diff] = param

          resource[:root] = ''
          resource[:context] = '/files'
          resource[:changes] = ["set #{file}/foo bar"]

          allow(File).to receive(:delete)
          allow(provider).to receive(:get_augeas_version).and_return('0.10.0')
          allow(provider).to receive('diff').with(file.to_s, "#{file}.augnew").and_return('diff')

          allow(augeas).to receive(:set).and_return(true)
          allow(augeas).to receive(:save).and_return(true)
          allow(augeas).to receive(:match).with('/augeas/events/saved').and_return(['/augeas/events/saved'])
          allow(augeas).to receive(:get).with('/augeas/events/saved').and_return("/files#{file}")
          allow(augeas).to receive(:set).with('/augeas/save', 'newfile')
        end

        if cfg && param
          it 'displays a diff' do
            expect(provider).to be_need_to_run

            expect(logs[0].message).to eq("\ndiff")
          end
        else
          it 'does not display a diff' do
            expect(provider).to be_need_to_run

            expect(logs).to be_empty
          end
        end
      end
    end

    # Ticket 2728 (diff files)
    describe 'and configured to show diffs' do
      before(:each) do
        Puppet[:show_diff] = true
        resource[:show_diff] = true

        resource[:root] = ''
        allow(provider).to receive(:get_augeas_version).and_return('0.10.0')
        allow(augeas).to receive(:set).and_return(true)
        allow(augeas).to receive(:save).and_return(true)
      end

      it 'displays a diff when a single file is shown to have been changed' do
        file = '/etc/hosts'
        allow(File).to receive(:delete)

        resource[:loglevel] = 'crit'
        resource[:context] = '/files'
        resource[:changes] = ["set #{file}/foo bar"]

        allow(augeas).to receive(:match).with('/augeas/events/saved').and_return(['/augeas/events/saved'])
        allow(augeas).to receive(:get).with('/augeas/events/saved').and_return("/files#{file}")
        expect(augeas).to receive(:set).with('/augeas/save', 'newfile')
        expect(provider).to receive('diff').with(file.to_s, "#{file}.augnew").and_return('diff')

        expect(provider).to be_need_to_run

        expect(logs[0].message).to eq("\ndiff")
        expect(logs[0].level).to eq(:crit)
      end

      it 'displays a diff for each file that is changed when changing many files' do
        file1 = '/etc/hosts'
        file2 = '/etc/resolv.conf'
        allow(File).to receive(:delete)

        resource[:context] = '/files'
        resource[:changes] = ["set #{file1}/foo bar", "set #{file2}/baz biz"]

        allow(augeas).to receive(:match).with('/augeas/events/saved').and_return(['/augeas/events/saved[1]', '/augeas/events/saved[2]'])
        allow(augeas).to receive(:get).with('/augeas/events/saved[1]').and_return("/files#{file1}")
        allow(augeas).to receive(:get).with('/augeas/events/saved[2]').and_return("/files#{file2}")
        expect(augeas).to receive(:set).with('/augeas/save', 'newfile')
        expect(provider).to receive(:diff).with(file1.to_s, "#{file1}.augnew").and_return("diff #{file1}")
        expect(provider).to receive(:diff).with(file2.to_s, "#{file2}.augnew").and_return("diff #{file2}")

        expect(provider).to be_need_to_run

        expect(logs.map(&:message)).to include("\ndiff #{file1}", "\ndiff #{file2}")
        expect(logs.map(&:level)).to eq([:notice, :notice])
      end

      describe 'and resource[:root] is set' do
        it 'calls diff when a file is shown to have been changed' do
          root = '/tmp/foo'
          file = '/etc/hosts'
          allow(File).to receive(:delete)

          resource[:context] = '/files'
          resource[:changes] = ["set #{file}/foo bar"]
          resource[:root] = root

          allow(augeas).to receive(:match).with('/augeas/events/saved').and_return(['/augeas/events/saved'])
          allow(augeas).to receive(:get).with('/augeas/events/saved').and_return("/files#{file}")
          expect(augeas).to receive(:set).with('/augeas/save', 'newfile')
          expect(provider).to receive(:diff).with("#{root}#{file}", "#{root}#{file}.augnew").and_return('diff')

          expect(provider).to be_need_to_run

          expect(logs[0].message).to eq("\ndiff")
          expect(logs[0].level).to eq(:notice)
        end
      end

      it 'does not call diff if no files change' do
        file = '/etc/hosts'

        resource[:context] = '/files'
        resource[:changes] = ["set #{file}/foo bar"]

        allow(augeas).to receive(:match).with('/augeas/events/saved').and_return([])
        expect(augeas).to receive(:set).with('/augeas/save', 'newfile')
        expect(augeas).to receive(:get).with('/augeas/events/saved').never
        expect(augeas).to receive(:close)

        expect(provider).to receive(:diff).never
        expect(provider).not_to be_need_to_run
      end

      it 'cleanups the .augnew file' do
        file = '/etc/hosts'

        resource[:context] = '/files'
        resource[:changes] = ["set #{file}/foo bar"]

        allow(augeas).to receive(:match).with('/augeas/events/saved').and_return(['/augeas/events/saved'])
        allow(augeas).to receive(:get).with('/augeas/events/saved').and_return("/files#{file}")
        expect(augeas).to receive(:set).with('/augeas/save', 'newfile')
        expect(augeas).to receive(:close)

        expect(File).to receive(:delete).with(file + '.augnew')

        expect(provider).to receive(:diff).with(file.to_s, "#{file}.augnew").and_return('')
        expect(provider).to be_need_to_run
      end

      # Workaround for Augeas bug #264 which reports filenames twice
      it 'handles duplicate /augeas/events/saved filenames' do
        file = '/etc/hosts'

        resource[:context] = '/files'
        resource[:changes] = ["set #{file}/foo bar"]

        allow(augeas).to receive(:match).with('/augeas/events/saved').and_return(['/augeas/events/saved[1]', '/augeas/events/saved[2]'])
        allow(augeas).to receive(:get).with('/augeas/events/saved[1]').and_return("/files#{file}")
        allow(augeas).to receive(:get).with('/augeas/events/saved[2]').and_return("/files#{file}")
        expect(augeas).to receive(:set).with('/augeas/save', 'newfile')
        expect(augeas).to receive(:close)

        expect(File).to receive(:delete).with(file + '.augnew').once

        expect(provider).to receive(:diff).with(file.to_s, "#{file}.augnew").and_return('').once
        expect(provider).to be_need_to_run
      end

      it 'fails with an error if saving fails' do
        file = '/etc/hosts'

        resource[:context] = '/files'
        resource[:changes] = ["set #{file}/foo bar"]

        allow(augeas).to receive(:save).and_return(false)
        allow(augeas).to receive(:match).with('/augeas/events/saved').and_return([])
        expect(augeas).to receive(:close)

        expect(provider).to receive(:diff).never
        expect(provider).to receive(:print_put_errors)
        expect { provider.need_to_run? }.to raise_error(Puppet::Error)
      end
    end
  end

  describe 'augeas execution integration' do
    let(:augeas) { instance_double('Augeas', load: nil) }

    before(:each) do
      allow(augeas).to receive('close')
      allow(augeas).to receive(:match).with('/augeas/events/saved').and_return([])

      provider.aug = augeas
      allow(provider).to receive(:get_augeas_version).and_return('0.3.5')
    end

    it 'handles set commands' do
      resource[:changes] = 'set JarJar Binks'
      resource[:context] = '/some/path/'
      expect(augeas).to receive(:set).with('/some/path/JarJar', 'Binks').and_return(true)
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    it 'handles rm commands' do
      resource[:changes] = 'rm /Jar/Jar'
      expect(augeas).to receive(:rm).with('/Jar/Jar')
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    it 'handles remove commands' do
      resource[:changes] = 'remove /Jar/Jar'
      expect(augeas).to receive(:rm).with('/Jar/Jar')
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    it 'handles clear commands' do
      resource[:changes] = 'clear Jar/Jar'
      resource[:context] = '/foo/'
      expect(augeas).to receive(:clear).with('/foo/Jar/Jar').and_return(true)
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    describe 'touch command' do
      it 'clears missing path' do
        resource[:changes] = 'touch Jar/Jar'
        resource[:context] = '/foo/'
        expect(augeas).to receive(:match).with('/foo/Jar/Jar').and_return([])
        expect(augeas).to receive(:clear).with('/foo/Jar/Jar').and_return(true)
        expect(augeas).to receive(:save).and_return(true)
        expect(augeas).to receive(:close)
        expect(provider.execute_changes).to eq(:executed)
      end

      it 'does not change on existing path' do
        resource[:changes] = 'touch Jar/Jar'
        resource[:context] = '/foo/'
        expect(augeas).to receive(:match).with('/foo/Jar/Jar').and_return(['/foo/Jar/Jar'])
        expect(augeas).to receive(:clear).never
        expect(augeas).to receive(:save).and_return(true)
        expect(augeas).to receive(:close)
        expect(provider.execute_changes).to eq(:executed)
      end
    end

    it 'handles ins commands with before' do
      resource[:changes] = 'ins Binks before Jar/Jar'
      resource[:context] = '/foo'
      expect(augeas).to receive(:insert).with('/foo/Jar/Jar', 'Binks', true)
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    it 'handles ins commands with after' do
      resource[:changes] = 'ins Binks after /Jar/Jar'
      resource[:context] = '/foo'
      expect(augeas).to receive(:insert).with('/Jar/Jar', 'Binks', false)
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    it 'handles ins with no context' do
      resource[:changes] = 'ins Binks after /Jar/Jar'
      expect(augeas).to receive(:insert).with('/Jar/Jar', 'Binks', false)
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    it 'handles multiple commands' do
      resource[:changes] = ['ins Binks after /Jar/Jar', 'clear Jar/Jar']
      resource[:context] = '/foo/'
      expect(augeas).to receive(:insert).with('/Jar/Jar', 'Binks', false)
      expect(augeas).to receive(:clear).with('/foo/Jar/Jar').and_return(true)
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    it 'handles defvar commands' do
      resource[:changes] = 'defvar myjar Jar/Jar'
      resource[:context] = '/foo/'
      expect(augeas).to receive(:defvar).with('myjar', '/foo/Jar/Jar').and_return(true)
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    it 'passes through augeas variables without context' do
      resource[:changes] = ['defvar myjar Jar/Jar', 'set $myjar/Binks 1']
      resource[:context] = '/foo/'
      expect(augeas).to receive(:defvar).with('myjar', '/foo/Jar/Jar').and_return(true)
      # this is the important bit, shouldn't be /foo/$myjar/Binks
      expect(augeas).to receive(:set).with('$myjar/Binks', '1').and_return(true)
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    it 'handles defnode commands' do
      resource[:changes] = 'defnode newjar Jar/Jar[last()+1] Binks'
      resource[:context] = '/foo/'
      expect(augeas).to receive(:defnode).with('newjar', '/foo/Jar/Jar[last()+1]', 'Binks').and_return(true)
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    it 'handles mv commands' do
      resource[:changes] = 'mv Jar/Jar Binks'
      resource[:context] = '/foo/'
      expect(augeas).to receive(:mv).with('/foo/Jar/Jar', '/foo/Binks').and_return(true)
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    it 'handles rename commands' do
      resource[:changes] = 'rename Jar/Jar Binks'
      resource[:context] = '/foo/'
      expect(augeas).to receive(:rename).with('/foo/Jar/Jar', 'Binks').and_return(true)
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    it 'handles setm commands' do
      resource[:changes] = ['set test[1]/Jar/Jar Foo', 'set test[2]/Jar/Jar Bar', 'setm test Jar/Jar Binks']
      resource[:context] = '/foo/'
      expect(augeas).to receive(:respond_to?).with('setm').and_return(true)
      expect(augeas).to receive(:set).with('/foo/test[1]/Jar/Jar', 'Foo').and_return(true)
      expect(augeas).to receive(:set).with('/foo/test[2]/Jar/Jar', 'Bar').and_return(true)
      expect(augeas).to receive(:setm).with('/foo/test', 'Jar/Jar', 'Binks').and_return(true)
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    it 'throws error if setm command not supported' do
      resource[:changes] = ['set test[1]/Jar/Jar Foo', 'set test[2]/Jar/Jar Bar', 'setm test Jar/Jar Binks']
      resource[:context] = '/foo/'
      expect(augeas).to receive(:respond_to?).with('setm').and_return(false)
      expect(augeas).to receive(:set).with('/foo/test[1]/Jar/Jar', 'Foo').and_return(true)
      expect(augeas).to receive(:set).with('/foo/test[2]/Jar/Jar', 'Bar').and_return(true)
      expect { provider.execute_changes }.to raise_error RuntimeError, %r{command 'setm' not supported}
    end

    it 'handles clearm commands' do
      resource[:changes] = ['set test[1]/Jar/Jar Foo', 'set test[2]/Jar/Jar Bar', 'clearm test Jar/Jar']
      resource[:context] = '/foo/'
      expect(augeas).to receive(:respond_to?).with('clearm').and_return(true)
      expect(augeas).to receive(:set).with('/foo/test[1]/Jar/Jar', 'Foo').and_return(true)
      expect(augeas).to receive(:set).with('/foo/test[2]/Jar/Jar', 'Bar').and_return(true)
      expect(augeas).to receive(:clearm).with('/foo/test', 'Jar/Jar').and_return(true)
      expect(augeas).to receive(:save).and_return(true)
      expect(augeas).to receive(:close)
      expect(provider.execute_changes).to eq(:executed)
    end

    it 'throws error if clearm command not supported' do
      resource[:changes] = ['set test[1]/Jar/Jar Foo', 'set test[2]/Jar/Jar Bar', 'clearm test Jar/Jar']
      resource[:context] = '/foo/'
      expect(augeas).to receive(:respond_to?).with('clearm').and_return(false)
      expect(augeas).to receive(:set).with('/foo/test[1]/Jar/Jar', 'Foo').and_return(true)
      expect(augeas).to receive(:set).with('/foo/test[2]/Jar/Jar', 'Bar').and_return(true)
      expect { provider.execute_changes }.to raise_error(RuntimeError, %r{command 'clearm' not supported})
    end

    it 'throws error if saving failed' do
      resource[:changes] = ['set test[1]/Jar/Jar Foo', 'set test[2]/Jar/Jar Bar', 'clearm test Jar/Jar']
      resource[:context] = '/foo/'
      expect(augeas).to receive(:respond_to?).with('clearm').and_return(true)
      expect(augeas).to receive(:set).with('/foo/test[1]/Jar/Jar', 'Foo').and_return(true)
      expect(augeas).to receive(:set).with('/foo/test[2]/Jar/Jar', 'Bar').and_return(true)
      expect(augeas).to receive(:clearm).with('/foo/test', 'Jar/Jar').and_return(true)
      expect(augeas).to receive(:save).and_return(false)
      expect(provider).to receive(:print_put_errors)
      expect(augeas).to receive(:match).and_return([])
      expect { provider.execute_changes }.to raise_error(Puppet::Error)
    end
  end

  describe 'when making changes', if: Puppet.features.augeas? do
    it "does not clobber the file if it's a symlink" do
      allow(Puppet::Util::Storage).to receive(:store)

      link = tmpfile('link')
      target = tmpfile('target')
      FileUtils.touch(target)
      Puppet::FileSystem.symlink(target, link)

      resource = Puppet::Type.type(:augeas).new(
        name: 'test',
        incl: link,
        lens: 'Sshd.lns',
        changes: 'set PermitRootLogin no',
      )

      catalog = Puppet::Resource::Catalog.new
      catalog.add_resource resource

      catalog.apply

      expect(File.ftype(link)).to eq('link')
      expect(Puppet::FileSystem.readlink(link)).to eq(target)
      expect(File.read(target)).to match(%r{PermitRootLogin no})
    end
  end

  describe 'load/save failure reporting' do
    let(:augeas) { instance_double('Augeas') }

    before(:each) do
      allow(augeas).to receive('close')
      provider.aug = augeas
    end

    describe 'should find load errors' do
      before(:each) do
        allow(augeas).to receive(:match).with('/augeas//error').and_return(['/augeas/files/foo/error'])
        allow(augeas).to receive(:match).with('/augeas/files/foo/error/*').and_return(['/augeas/files/foo/error/path', '/augeas/files/foo/error/message'])
        allow(augeas).to receive(:get).with('/augeas/files/foo/error').and_return('some_failure')
        allow(augeas).to receive(:get).with('/augeas/files/foo/error/path').and_return('/foo')
        allow(augeas).to receive(:get).with('/augeas/files/foo/error/message').and_return('Failed to...')
      end

      it 'and output only to debug when no path supplied' do
        expect(provider).to receive(:debug).exactly(5).times
        expect(provider).to receive(:warning).never
        provider.print_load_errors(nil)
      end

      it 'and output a warning and to debug when path supplied' do
        expect(augeas).to receive(:match).with('/augeas/files/foo//error').and_return(['/augeas/files/foo/error'])
        expect(provider).to receive(:warning).once
        expect(provider).to receive(:debug).exactly(4).times
        provider.print_load_errors('/augeas/files/foo//error')
      end

      it "and output only to debug when path doesn't match" do
        expect(augeas).to receive(:match).with('/augeas/files/foo//error').and_return([])
        expect(provider).to receive(:warning).never
        expect(provider).to receive(:debug).exactly(5).times
        provider.print_load_errors('/augeas/files/foo//error')
      end
    end

    it 'finds load errors from lenses' do
      expect(augeas).to receive(:match).with('/augeas//error').twice.and_return(['/augeas/load/Xfm/error'])
      expect(augeas).to receive(:match).with('/augeas/load/Xfm/error/*').and_return([])
      expect(augeas).to receive(:get).with('/augeas/load/Xfm/error').and_return(['Could not find lens php.aug'])
      expect(provider).to receive(:warning).once
      expect(provider).to receive(:debug).twice
      provider.print_load_errors('/augeas//error')
    end

    it 'finds save errors and output to debug' do
      expect(augeas).to receive(:match).with("/augeas//error[. = 'put_failed']").and_return(['/augeas/files/foo/error'])
      expect(augeas).to receive(:match).with('/augeas/files/foo/error/*').and_return(['/augeas/files/foo/error/path', '/augeas/files/foo/error/message'])
      expect(augeas).to receive(:get).with('/augeas/files/foo/error').and_return('some_failure')
      expect(augeas).to receive(:get).with('/augeas/files/foo/error/path').and_return('/foo')
      expect(augeas).to receive(:get).with('/augeas/files/foo/error/message').and_return('Failed to...')
      expect(provider).to receive(:debug).exactly(5).times
      provider.print_put_errors
    end
  end

  # Run initialisation tests of the real Augeas library to test our open_augeas
  # method.  This relies on Augeas and ruby-augeas on the host to be
  # functioning.
  describe 'augeas lib initialisation', if: Puppet.features.augeas? do
    # Expect lenses for fstab and hosts
    it 'has loaded standard files by default' do
      aug = provider.open_augeas
      expect(aug).not_to eq(nil)
      expect(aug.match('/files/etc/fstab')).to eq(['/files/etc/fstab'])
      expect(aug.match('/files/etc/hosts')).to eq(['/files/etc/hosts'])
      expect(aug.match('/files/etc/test')).to eq([])
    end

    it 'reports load errors to debug only' do
      expect(provider).to receive(:print_load_errors).with(nil)
      aug = provider.open_augeas
      expect(aug).not_to eq(nil)
    end

    # Only the file specified should be loaded
    it 'loads one file if incl/lens used' do
      resource[:incl] = '/etc/hosts'
      resource[:lens] = 'Hosts.lns'

      expect(provider).to receive(:print_load_errors).with('/augeas//error')
      aug = provider.open_augeas
      expect(aug).not_to eq(nil)
      expect(aug.match('/files/etc/fstab')).to eq([])
      expect(aug.match('/files/etc/hosts')).to eq(['/files/etc/hosts'])
      expect(aug.match('/files/etc/test')).to eq([])
    end

    it 'alsoes load lenses from load_path' do
      resource[:load_path] = my_fixture_dir

      aug = provider.open_augeas
      expect(aug).not_to eq(nil)
      expect(aug.match('/files/etc/fstab')).to eq(['/files/etc/fstab'])
      expect(aug.match('/files/etc/hosts')).to eq(['/files/etc/hosts'])
      expect(aug.match('/files/etc/test')).to eq(['/files/etc/test'])
    end

    it "alsoes load lenses from pluginsync'd path" do
      Puppet[:libdir] = my_fixture_dir

      aug = provider.open_augeas
      expect(aug).not_to eq(nil)
      expect(aug.match('/files/etc/fstab')).to eq(['/files/etc/fstab'])
      expect(aug.match('/files/etc/hosts')).to eq(['/files/etc/hosts'])
      expect(aug.match('/files/etc/test')).to eq(['/files/etc/test'])
    end

    # Optimisations added for Augeas 0.8.2 or higher is available, see #7285
    describe '>= 0.8.2 optimisations', if: Puppet.features.augeas? && Facter.value(:augeasversion) && Puppet::Util::Package.versioncmp(Facter.value(:augeasversion), '0.8.2') >= 0 do
      it 'onlies load one file if relevant context given' do
        resource[:context] = '/files/etc/fstab'

        expect(provider).to receive(:print_load_errors).with('/augeas/files/etc/fstab//error')
        aug = provider.open_augeas
        expect(aug).not_to eq(nil)
        expect(aug.match('/files/etc/fstab')).to eq(['/files/etc/fstab'])
        expect(aug.match('/files/etc/hosts')).to eq([])
      end

      it 'onlies load one lens from load_path if context given' do
        resource[:context] = '/files/etc/test'
        resource[:load_path] = my_fixture_dir

        expect(provider).to receive(:print_load_errors).with('/augeas/files/etc/test//error')
        aug = provider.open_augeas
        expect(aug).not_to eq(nil)
        expect(aug.match('/files/etc/fstab')).to eq([])
        expect(aug.match('/files/etc/hosts')).to eq([])
        expect(aug.match('/files/etc/test')).to eq(['/files/etc/test'])
      end

      it "loads standard files if context isn't specific" do
        resource[:context] = '/files/etc'

        expect(provider).to receive(:print_load_errors).with(nil)
        aug = provider.open_augeas
        expect(aug).not_to eq(nil)
        expect(aug.match('/files/etc/fstab')).to eq(['/files/etc/fstab'])
        expect(aug.match('/files/etc/hosts')).to eq(['/files/etc/hosts'])
      end

      it 'does not optimise if the context is a complex path' do
        resource[:context] = "/files/*[label()='etc']"

        expect(provider).to receive(:print_load_errors).with(nil)
        aug = provider.open_augeas
        expect(aug).not_to eq(nil)
        expect(aug.match('/files/etc/fstab')).to eq(['/files/etc/fstab'])
        expect(aug.match('/files/etc/hosts')).to eq(['/files/etc/hosts'])
      end
    end
  end

  describe 'get_load_path' do
    it 'offers no load_path by default' do
      expect(provider.get_load_path(resource)).to eq('')
    end

    it 'offers one path from load_path' do
      resource[:load_path] = '/foo'
      expect(provider.get_load_path(resource)).to eq('/foo')
    end

    it 'offers multiple colon-separated paths from load_path' do
      resource[:load_path] = '/foo:/bar:/baz'
      expect(provider.get_load_path(resource)).to eq('/foo:/bar:/baz')
    end

    it 'offers multiple paths in array from load_path' do
      resource[:load_path] = ['/foo', '/bar', '/baz']
      expect(provider.get_load_path(resource)).to eq('/foo:/bar:/baz')
    end

    context 'when running application is agent' do
      before(:each) do
        Puppet[:libdir] = my_fixture_dir
        allow(Puppet.run_mode).to receive(:name).and_return(:agent)
      end

      it 'offers pluginsync augeas/lenses subdir' do
        expect(provider.get_load_path(resource)).to eq("#{my_fixture_dir}/augeas/lenses")
      end

      it 'offers both pluginsync and load_path paths' do
        resource[:load_path] = ['/foo', '/bar', '/baz']
        expect(provider.get_load_path(resource)).to eq("/foo:/bar:/baz:#{my_fixture_dir}/augeas/lenses")
      end
    end

    context 'when running application is not agent' do
      before(:each) do
        allow(Puppet.run_mode).to receive(:name).and_return(:user)

        env = Puppet::Node::Environment.create('root', ['/modules/foobar'])
        allow(Puppet).to receive(:lookup).and_return(env)
        allow(env).to receive(:each_plugin_directory).and_yield('/modules/foobar')

        resource[:load_path] = ['/foo', '/bar', '/baz']
      end

      it 'offers both load_path and module lenses path when available' do
        allow(File).to receive(:exist?).with('/modules/foobar/augeas/lenses').and_return(true)
        expect(provider.get_load_path(resource)).to eq('/foo:/bar:/baz:/modules/foobar/augeas/lenses')
      end

      it 'offers only load_path if module lenses path is not available' do
        allow(File).to receive(:exist?).with('/modules/foobar/augeas/lenses').and_return(false)
        expect(provider.get_load_path(resource)).to eq('/foo:/bar:/baz')
      end
    end
  end
end
