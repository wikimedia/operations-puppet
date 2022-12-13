#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:augeasprovider).provider(:default)

describe provider_class do
  let(:augeas_handler) do
    instance_double(Augeas)
  end

  context 'empty provider' do
    class Empty < provider_class
    end

    subject(:provider) { Empty }

    describe '#lens' do
      it "fails as default lens isn't set" do
        expect { provider.lens }.to raise_error(Puppet::Error, 'Lens is not provided')
      end
    end

    describe '#target' do
      it 'fails if no default or resource file' do
        expect { provider.target }.to raise_error(Puppet::Error, 'No target file given')
      end

      it 'returns resource file if set' do
        provider.target(target: '/foo').should == '/foo'
      end

      it 'strips trailing / from resource file' do
        provider.target(target: '/foo/').should == '/foo'
      end
    end

    describe '#resource_path' do
      it 'calls #target if no resource path block set' do
        resource = { name: 'foo' }
        provider.expects(:target).with(resource)
        provider.resource_path(resource).should == '/foo'
      end

      it 'calls #target if a resource path block is set' do
        resource = { name: 'foo' }
        provider.resource_path { '/files/test' }
        provider.resource_path(resource).should == '/files/test'
      end
    end

    describe '#readquote' do
      it 'returns :double when value is double-quoted' do
        provider.readquote('"foo"').should == :double
      end

      it 'returns :single when value is single-quoted' do
        provider.readquote("'foo'").should == :single
      end

      it 'returns nil when value is not quoted' do
        provider.readquote('foo').should be_nil
      end

      it 'returns nil when value is not properly quoted' do
        provider.readquote("'foo").should be_nil
        provider.readquote("'foo\"").should be_nil
        provider.readquote('"foo').should be_nil
        provider.readquote("\"foo'").should be_nil
      end
    end

    describe '#whichquote' do
      it 'return an empty string for alphanum values' do
        provider.whichquote('foo').should == ''
      end

      it 'double-quotes by default for values containing spaces or special characters' do
        provider.whichquote('foo bar').should eq('"')
        provider.whichquote('foo&bar').should eq('"')
        provider.whichquote('foo;bar').should eq('"')
        provider.whichquote('foo<bar').should eq('"')
        provider.whichquote('foo>bar').should eq('"')
        provider.whichquote('foo(bar').should eq('"')
        provider.whichquote('foo)bar').should eq('"')
        provider.whichquote('foo|bar').should eq('"')
      end

      it 'calls #readquote and use its value when oldvalue is passed' do
        provider.whichquote('foo', nil, "'bar'").should eq("'")
        provider.whichquote('foo', nil, '"bar"').should eq('"')
        provider.whichquote('foo', nil, 'bar').should eq('')
        provider.whichquote('foo bar', nil, "'bar'").should eq("'")
      end

      it 'double-quotes special values when oldvalue is not quoted' do
        provider.whichquote('foo bar', nil, 'bar').should eq('"')
      end

      it 'uses the :quoted parameter when present' do
        resource = {}
        resource.stubs(:parameters).returns([:quoted])

        resource[:quoted] = :single
        provider.whichquote('foo', resource).should eq("'")

        resource[:quoted] = :double
        provider.whichquote('foo', resource).should eq('"')

        resource[:quoted] = :auto
        provider.whichquote('foo', resource).should eq('')
        provider.whichquote('foo bar', resource).should eq('"')
      end
    end

    describe '#quoteit' do
      it 'does not do anything by default for alphanum values' do
        provider.quoteit('foo').should == 'foo'
      end

      it 'double-quotes by default for values containing spaces or special characters' do
        provider.quoteit('foo bar').should eq('"foo bar"')
        provider.quoteit('foo&bar').should eq('"foo&bar"')
        provider.quoteit('foo;bar').should eq('"foo;bar"')
        provider.quoteit('foo<bar').should eq('"foo<bar"')
        provider.quoteit('foo>bar').should eq('"foo>bar"')
        provider.quoteit('foo(bar').should eq('"foo(bar"')
        provider.quoteit('foo)bar').should eq('"foo)bar"')
        provider.quoteit('foo|bar').should eq('"foo|bar"')
      end

      it 'calls #readquote and use its value when oldvalue is passed' do
        provider.quoteit('foo', nil, "'bar'").should eq("'foo'")
        provider.quoteit('foo', nil, '"bar"').should eq('"foo"')
        provider.quoteit('foo', nil, 'bar').should eq('foo')
        provider.quoteit('foo bar', nil, "'bar'").should eq("'foo bar'")
      end

      it 'double-quotes special values when oldvalue is not quoted' do
        provider.quoteit('foo bar', nil, 'bar').should eq('"foo bar"')
      end

      it 'uses the :quoted parameter when present' do
        resource = {}
        resource.stubs(:parameters).returns([:quoted])

        resource[:quoted] = :single
        provider.quoteit('foo', resource).should eq("'foo'")
        resource[:quoted] = :double
        provider.quoteit('foo', resource).should eq('"foo"')
        resource[:quoted] = :auto
        provider.quoteit('foo', resource).should eq('foo')
        provider.quoteit('foo bar', resource).should eq('"foo bar"')
      end
    end

    describe '#unquoteit' do
      it 'does not do anything when value is not quoted' do
        provider.unquoteit('foo bar').should == 'foo bar'
      end

      it 'does not do anything when value is badly quoted' do
        provider.unquoteit('"foo bar').should eq('"foo bar')
        provider.unquoteit("'foo bar").should eq("'foo bar")
        provider.unquoteit("'foo bar\"").should eq("'foo bar\"")
      end

      it 'returns unquoted value' do
        provider.unquoteit('"foo bar"').should eq('foo bar')
        provider.unquoteit("'foo bar'").should eq('foo bar')
      end
    end

    describe '#parsed_as?' do
      context 'when text_store is supported' do
        it 'returns false when text_store fails' do
          Augeas.expects(:open).with(nil, nil, Augeas::NO_MODL_AUTOLOAD).yields(augeas_handler)
          augeas_handler.expects(:respond_to?).with(:text_store).returns(true)
          augeas_handler.expects(:set).with('/input', 'foo').returns(nil)
          augeas_handler.expects(:text_store).with('Baz.lns', '/input', '/parsed').returns(false)
          provider.parsed_as?('foo', 'bar', 'Baz.lns').should == false
        end

        it 'returns false when path is not found' do
          Augeas.expects(:open).with(nil, nil, Augeas::NO_MODL_AUTOLOAD).yields(augeas_handler)
          augeas_handler.expects(:respond_to?).with(:text_store).returns(true)
          augeas_handler.expects(:set).with('/input', 'foo').returns(nil)
          augeas_handler.expects(:text_store).with('Baz.lns', '/input', '/parsed').returns(true)
          augeas_handler.expects(:match).with('/parsed/bar').returns([])
          provider.parsed_as?('foo', 'bar', 'Baz.lns').should == false
        end

        it 'returns true when path is found' do
          Augeas.expects(:open).with(nil, nil, Augeas::NO_MODL_AUTOLOAD).yields(augeas_handler)
          augeas_handler.expects(:respond_to?).with(:text_store).returns(true)
          augeas_handler.expects(:set).with('/input', 'foo').returns(nil)
          augeas_handler.expects(:text_store).with('Baz.lns', '/input', '/parsed').returns(true)
          augeas_handler.expects(:match).with('/parsed/bar').returns(['/parsed/bar'])
          provider.parsed_as?('foo', 'bar', 'Baz.lns').should == true
        end
      end

      context 'when text_store is not supported' do
        it 'returns true if path is found in tempfile' do
          Augeas.expects(:open).with(nil, nil, Augeas::NO_MODL_AUTOLOAD).yields(augeas_handler)
          augeas_handler.expects(:respond_to?).with(:text_store).returns(false)
          augeas_handler.expects(:text_store).never
          augeas_handler.expects(:transform)
          augeas_handler.expects(:load!)
          augeas_handler.expects(:match).returns(['/files/tmp/aug_text_store20140410-8734-icc4xn/bar'])
          provider.parsed_as?('foo', 'bar', 'Baz.lns').should == true
        end
      end
    end

    describe '#attr_aug_reader' do
      it 'creates a class method' do
        provider.attr_aug_reader(:foo, {})
        provider.method_defined?('attr_aug_reader_foo').should be true
      end
    end

    describe '#attr_aug_writer' do
      it 'creates a class method' do
        provider.attr_aug_writer(:foo, {})
        provider.method_defined?('attr_aug_writer_foo').should be true
      end
    end

    describe '#attr_aug_accessor' do
      it 'calls #attr_aug_reader and #attr_aug_writer' do
        name = :foo
        opts = { bar: 'baz' }
        provider.expects(:attr_aug_reader).with(name, opts)
        provider.expects(:attr_aug_writer).with(name, opts)
        provider.attr_aug_accessor(name, opts)
      end
    end

    describe '#next_seq' do
      it 'returns 1 with no paths' do
        provider.new.next_seq([]).should == '1'
      end

      it 'returns 1 with only comments' do
        provider.new.next_seq(['/files/etc/hosts/#comment[1]']).should == '1'
      end

      it 'returns 2 when 1 exists' do
        provider.new.next_seq(['/files/etc/hosts/1']).should == '2'
      end

      it 'returns 42 when 1..41 exists' do
        provider.new.next_seq((1..41).map { |n| "/files/etc/hosts/#{n}" }).should == '42'
      end
    end
  end

  context 'working provider' do
    class Test < provider_class
      lens { 'Hosts.lns' }
      default_file { '/foo' }
      resource_path { |r, _p| r[:test] }
      attr_accessor :resource
    end

    subject(:provider) { Test }

    let(:tmptarget) { aug_fixture('full') }
    let(:thetarget) { tmptarget.path }
    let(:resource) { { target: thetarget } }

    # Class methods
    describe '#lens' do
      it 'allows retrieval of the set lens' do
        provider.lens.should == 'Hosts.lns'
      end
    end

    describe '#target' do
      it 'allows retrieval of the set default file' do
        provider.target.should == '/foo'
      end
    end

    describe '#resource_path' do
      it 'calls block to get the resource path' do
        provider.resource_path(test: 'bar').should == 'bar'
      end
    end

    describe '#loadpath' do
      it 'returns nil by default' do
        provider.send(:loadpath).should be_nil
      end

      it 'adds libdir/augeas/lenses/ to the loadpath if it exists' do
        plugindir = File.join(Puppet[:libdir], 'augeas', 'lenses')
        File.expects(:exist?).with(plugindir).returns(true)
        provider.send(:loadpath).should == plugindir
      end
    end

    describe '#augopen' do
      before(:each) do
        provider.expects(:augsave!).never
      end

      context 'on Puppet < 3.4.0' do
        before :each do
          provider.stubs(:supported?).with(:post_resource_eval).returns(false)
        end

        it 'calls Augeas#close when given a block' do
          provider.augopen(resource) do |aug|
            aug.expects(:close)
          end
        end

        it 'does not call Augeas#close when not given a block' do
          Augeas.any_instance.expects(:close).never # rubocop:disable RSpec/AnyInstance
          provider.augopen(resource)
        end
      end

      context 'on Puppet >= 3.4.0' do
        before :each do
          provider.stubs(:supported?).with(:post_resource_eval).returns(true)
        end

        it 'does not call Augeas#close when given a block' do
          Augeas.any_instance.expects(:close).never # rubocop:disable RSpec/AnyInstance
          provider.augopen(resource)
        end

        it 'calls Augeas#close when calling post_resource_eval' do
          provider.augopen(resource) do |aug|
            aug.expects(:close)
            provider.post_resource_eval
          end
        end
      end

      it 'calls #setvars when given a block' do
        provider.expects(:setvars)
        provider.augopen(resource) { |aug| }
      end

      it 'does not call #setvars when not given a block' do
        provider.expects(:setvars).never
        provider.augopen(resource)
      end

      context 'with broken file' do
        let(:tmptarget) { aug_fixture('broken') }

        it 'fails if the file fails to load' do
          expect { provider.augopen(resource) {} }.to raise_error(Puppet::Error, %r{Augeas didn't load #{Regexp.escape(thetarget)} with Hosts.lns: Iterated lens matched less than it should})
        end
      end
    end

    describe '#augopen!' do
      context 'on Puppet < 3.4.0' do
        before :each do
          provider.stubs(:supported?).with(:post_resource_eval).returns(false)
        end

        it 'calls Augeas#close when given a block' do
          provider.augopen!(resource) do |aug|
            aug.expects(:close)
          end
        end

        it 'does not call Augeas#close when not given a block' do
          Augeas.any_instance.expects(:close).never # rubocop:disable RSpec/AnyInstance
          provider.augopen!(resource)
        end
      end

      context 'on Puppet >= 3.4.0' do
        before :each do
          provider.stubs(:supported?).with(:post_resource_eval).returns(true)
        end

        it 'does not call Augeas#close when given a block' do
          Augeas.any_instance.expects(:close).never # rubocop:disable RSpec/AnyInstance
          provider.augopen!(resource)
        end
      end

      it 'calls #setvars when given a block' do
        provider.expects(:setvars)
        provider.augopen!(resource) { |aug| }
      end

      it 'does not call #setvars when not given a block' do
        provider.expects(:setvars).never
        provider.augopen!(resource)
      end

      context 'on Puppet < 3.4.0' do
        before :each do
          provider.stubs(:supported?).with(:post_resource_eval).returns(false)
        end

        it 'calls #augsave when given a block' do
          provider.expects(:augsave!)
          provider.augopen!(resource) { |aug| }
        end

        it 'does not call #augsave when not given a block' do
          provider.expects(:augsave!).never
          provider.augopen!(resource)
        end
      end

      context 'on Puppet >= 3.4.0' do
        before :each do
          provider.stubs(:supported?).with(:post_resource_eval).returns(true)
        end

        it 'does not call #augsave when given a block' do
          provider.expects(:augsave!).never
          provider.augopen!(resource) { |aug| }
        end

        it 'does not call #augsave when not given a block' do
          provider.expects(:augsave!).never
          provider.augopen!(resource)
        end

        it 'calls Augeas#close when calling post_resource_eval' do
          provider.augopen(resource) do |aug|
            aug.expects(:close)
            provider.post_resource_eval
          end
        end
      end

      context 'with broken file' do
        let(:tmptarget) { aug_fixture('broken') }

        it 'fails if the file fails to load' do
          expect { provider.augopen!(resource) {} }.to raise_error(Puppet::Error, %r{Augeas didn't load #{Regexp.escape(thetarget)} with Hosts.lns: Iterated lens matched less than it should})
        end
      end

      context 'when raising an exception in the block' do
        it 'toes raise the right exception' do
          expect {
            provider.augopen! do |_aug|
              raise Puppet::Error, 'My error'
            end
          }.to raise_error Puppet::Error, 'My error'
        end
      end
    end

    describe '#augsave' do
      it 'prints /augeas//error on save' do
        provider.augopen(resource) do |aug|
          # Prepare an invalid save
          provider.stubs(:debug)
          aug.rm("/files#{thetarget}/*/ipaddr").should_not eq(0)
          -> { provider.augsave!(aug) }.should raise_error Augeas::Error, %r{Failed to save Augeas tree}
        end
      end
    end

    describe '#path_label' do
      it 'uses Augeas#label when available' do
        provider.augopen(resource) do |aug|
          aug.expects(:respond_to?).with(:label).returns true
          aug.expects(:label).with('/files/foo[2]').returns 'foo'
          provider.path_label(aug, '/files/foo[2]').should == 'foo'
        end
      end

      it 'emulates Augeas#label when it is not available' do
        provider.augopen(resource) do |aug|
          aug.expects(:respond_to?).with(:label).returns false
          aug.expects(:label).with('/files/bar[4]').never
          provider.path_label(aug, '/files/bar[4]').should == 'bar'
        end
      end

      it 'emulates Augeas#label when no label is found in the tree' do
        provider.augopen(resource) do |aug|
          aug.expects(:respond_to?).with(:label).returns true
          aug.expects(:label).with('/files/baz[15]').returns nil
          provider.path_label(aug, '/files/baz[15]').should == 'baz'
        end
      end
    end

    describe '#setvars' do
      it 'calls Augeas#defnode to set $target, Augeas#defvar to set $resource and Augeas#set to set /augeas/context when resource is passed' do
        provider.augopen(resource) do |aug|
          aug.expects(:context=).with("/files#{thetarget}")
          aug.expects(:defnode).with('target', "/files#{thetarget}", nil)
          provider.expects(:resource_path).with(resource).returns('/files/foo')
          aug.expects(:defvar).with('resource', '/files/foo')
          provider.setvars(aug, resource)
        end
      end

      it 'calls Augeas#defnode to set $target but not $resource when no resource is passed' do
        provider.augopen(resource) do |aug|
          aug.expects(:defnode).with('target', '/files/foo', nil)
          aug.expects(:defvar).never
          provider.setvars(aug)
        end
      end
    end

    describe '#attr_aug_reader' do
      it 'creates a class method using :string' do
        provider.attr_aug_reader(:foo, {})
        provider.method_defined?('attr_aug_reader_foo').should be true

        Augeas.any_instance.expects(:get).with('$resource/foo').returns('bar') # rubocop:disable RSpec/AnyInstance
        provider.augopen(resource) do |aug|
          provider.attr_aug_reader_foo(aug).should == 'bar'
        end
      end

      it 'creates a class method using :array with :split_by' do
        provider.attr_aug_reader(:foo, type: :array, split_by: ',')
        provider.method_defined?('attr_aug_reader_foo').should be true

        provider.augopen(resource) do |aug|
          aug.expects(:get).with('$resource/foo').returns('baz,bazz')
          provider.attr_aug_reader_foo(aug).should == ['baz', 'bazz']
        end
      end

      it 'creates a class method using :array and no sublabel' do
        provider.attr_aug_reader(:foo, type: :array)
        provider.method_defined?('attr_aug_reader_foo').should be true

        rpath = "/files#{thetarget}/test/foo"
        provider.augopen(resource) do |aug|
          aug.expects(:match).with('$resource/foo').returns(["#{rpath}[1]", "#{rpath}[2]"])
          aug.expects(:get).with("#{rpath}[1]").returns('baz')
          aug.expects(:get).with("#{rpath}[2]").returns('bazz')
          provider.attr_aug_reader_foo(aug).should == ['baz', 'bazz']
        end
      end

      it 'creates a class method using :array and a :seq sublabel' do
        provider.attr_aug_reader(:foo, type: :array, sublabel: :seq)
        provider.method_defined?('attr_aug_reader_foo').should be true

        rpath = "/files#{thetarget}/test/foo"
        provider.augopen(resource) do |aug|
          aug.expects(:match).with('$resource/foo').returns(["#{rpath}[1]", "#{rpath}[2]"])
          aug.expects(:match).with("#{rpath}[1]/*[label()=~regexp('[0-9]+')]").returns(["#{rpath}[1]/1"])
          aug.expects(:get).with("#{rpath}[1]/1").returns('val11')
          aug.expects(:match).with("#{rpath}[2]/*[label()=~regexp('[0-9]+')]").returns(["#{rpath}[2]/1", "#{rpath}[2]/2"])
          aug.expects(:get).with("#{rpath}[2]/1").returns('val21')
          aug.expects(:get).with("#{rpath}[2]/2").returns('val22')
          provider.attr_aug_reader_foo(aug).should == ['val11', 'val21', 'val22']
        end
      end

      it 'creates a class method using :array and a string sublabel' do
        provider.attr_aug_reader(:foo, type: :array, sublabel: 'sl')
        provider.method_defined?('attr_aug_reader_foo').should be true

        rpath = "/files#{thetarget}/test/foo"
        provider.augopen(resource) do |aug|
          aug.expects(:match).with('$resource/foo').returns(["#{rpath}[1]", "#{rpath}[2]"])
          aug.expects(:match).with("#{rpath}[1]/sl").returns(["#{rpath}[1]/sl"])
          aug.expects(:get).with("#{rpath}[1]/sl").returns('val11')
          aug.expects(:match).with("#{rpath}[2]/sl").returns(["#{rpath}[2]/sl[1]", "#{rpath}[2]/sl[2]"])
          aug.expects(:get).with("#{rpath}[2]/sl[1]").returns('val21')
          aug.expects(:get).with("#{rpath}[2]/sl[2]").returns('val22')
          provider.attr_aug_reader_foo(aug).should == ['val11', 'val21', 'val22']
        end
      end

      it 'creates a class method using :hash and no sublabel' do
        expect {
          provider.attr_aug_reader(:foo, type: :hash, default: 'deflt')
        }.to raise_error(RuntimeError, %r{You must provide a sublabel})
      end

      it 'creates a class method using :hash and sublabel' do
        provider.attr_aug_reader(:foo, type: :hash, sublabel: 'sl', default: 'deflt')
        provider.method_defined?('attr_aug_reader_foo').should be true

        rpath = "/files#{thetarget}/test/foo"
        provider.augopen(resource) do |aug|
          aug.expects(:match).with('$resource/foo').returns(["#{rpath}[1]", "#{rpath}[2]"])
          aug.expects(:get).with("#{rpath}[1]").returns('baz')
          aug.expects(:get).with("#{rpath}[1]/sl").returns('bazval')
          aug.expects(:get).with("#{rpath}[2]").returns('bazz')
          aug.expects(:get).with("#{rpath}[2]/sl").returns(nil)
          provider.attr_aug_reader_foo(aug).should == { 'baz' => 'bazval', 'bazz' => 'deflt' }
        end
      end

      it 'creates a class method using wrong type' do
        expect {
          provider.attr_aug_reader(:foo, type: :foo)
        }.to raise_error(RuntimeError, %r{Invalid type: foo})
      end
    end

    describe '#attr_aug_writer' do
      it 'creates a class method using :string' do
        provider.attr_aug_writer(:foo, {})
        provider.method_defined?('attr_aug_writer_foo').should be true

        provider.augopen(resource) do |aug|
          aug.expects(:set).with('$resource/foo', 'bar')
          provider.attr_aug_writer_foo(aug, 'bar')
          aug.expects(:clear).with('$resource/foo')
          provider.attr_aug_writer_foo(aug)
        end
      end

      it 'creates a class method using :string with :rm_node' do
        provider.attr_aug_writer(:foo, rm_node: true)
        provider.method_defined?('attr_aug_writer_foo').should be true

        provider.augopen(resource) do |aug|
          aug.expects(:set).with('$resource/foo', 'bar')
          provider.attr_aug_writer_foo(aug, 'bar')
          aug.expects(:rm).with('$resource/foo')
          provider.attr_aug_writer_foo(aug)
        end
      end

      it 'creates a class method using :array with :split_by' do
        provider.attr_aug_writer(:foo, type: :array, split_by: ',')
        provider.method_defined?('attr_aug_writer_foo').should be true

        provider.augopen(resource) do |aug|
          # one value
          aug.expects(:set).with('$resource/foo', 'bar')
          provider.attr_aug_writer_foo(aug, ['bar'])
          # multiple values
          aug.expects(:set).with('$resource/foo', 'bar,baz')
          provider.attr_aug_writer_foo(aug, ['bar', 'baz'])
          # purge values
          aug.expects(:rm).with('$resource/foo')
          provider.attr_aug_writer_foo(aug, [])
          aug.expects(:rm).with('$resource/foo')
          provider.attr_aug_writer_foo(aug)
        end
      end

      it 'creates a class method using :array and no sublabel' do
        provider.attr_aug_writer(:foo, type: :array)
        provider.method_defined?('attr_aug_writer_foo').should be true

        provider.augopen(resource) do |aug|
          aug.expects(:rm).with('$resource/foo')
          aug.expects(:set).with('$resource/foo[1]', 'bar')
          provider.attr_aug_writer_foo(aug)
          aug.expects(:rm).with('$resource/foo')
          aug.expects(:set).with('$resource/foo[2]', 'baz')
          provider.attr_aug_writer_foo(aug, ['bar', 'baz'])
        end
      end

      it 'creates a class method using :array and a :seq sublabel' do
        provider.attr_aug_writer(:foo, type: :array, sublabel: :seq)
        provider.method_defined?('attr_aug_writer_foo').should be true

        provider.augopen(resource) do |aug|
          aug.expects(:rm).with('$resource/foo')
          provider.attr_aug_writer_foo(aug)
          aug.expects(:rm).with("$resource/foo/*[label()=~regexp('[0-9]+')]")
          aug.expects(:set).with('$resource/foo/1', 'bar')
          aug.expects(:set).with('$resource/foo/2', 'baz')
          provider.attr_aug_writer_foo(aug, ['bar', 'baz'])
        end
      end

      it 'creates a class method using :array and a string sublabel' do
        provider.attr_aug_writer(:foo, type: :array, sublabel: 'sl')
        provider.method_defined?('attr_aug_writer_foo').should be true

        provider.augopen(resource) do |aug|
          aug.expects(:rm).with('$resource/foo')
          provider.attr_aug_writer_foo(aug)
          aug.expects(:rm).with('$resource/foo/sl')
          aug.expects(:set).with('$resource/foo/sl[1]', 'bar')
          aug.expects(:set).with('$resource/foo/sl[2]', 'baz')
          provider.attr_aug_writer_foo(aug, ['bar', 'baz'])
        end
      end

      it 'creates a class method using :hash and no sublabel' do
        expect {
          provider.attr_aug_writer(:foo, type: :hash, default: 'deflt')
        }.to raise_error(RuntimeError, %r{You must provide a sublabel})
      end

      it 'creates a class method using :hash and sublabel' do
        provider.attr_aug_writer(:foo, type: :hash, sublabel: 'sl', default: 'deflt')
        provider.method_defined?('attr_aug_writer_foo').should be true

        provider.augopen(resource) do |aug|
          aug.expects(:rm).with('$resource/foo')
          aug.expects(:set).with("$resource/foo[.='baz']", 'baz')
          aug.expects(:set).with("$resource/foo[.='baz']/sl", 'bazval')
          aug.expects(:set).with("$resource/foo[.='bazz']", 'bazz')
          aug.expects(:set).with("$resource/foo[.='bazz']/sl", 'bazzval').never
          provider.attr_aug_writer_foo(aug, 'baz' => 'bazval', 'bazz' => 'deflt')
        end
      end

      it 'creates a class method using wrong type' do
        expect {
          provider.attr_aug_writer(:foo, type: :foo)
        }.to raise_error(RuntimeError, %r{Invalid type: foo})
      end
    end
  end
end
