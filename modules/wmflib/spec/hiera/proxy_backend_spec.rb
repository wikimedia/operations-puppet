require 'spec_helper'
require 'hiera'
require 'hiera/backend/proxy_backend'

describe 'proxy_backend' do
  before :each do
    # Build a node with two roles applied
    @hiera = Hiera.new({:config => 'spec/fixtures/hiera.proxy.yaml'})
    Hiera::Config.load('spec/fixtures/hiera.proxy.yaml')
    @backend = Hiera::Backend::Proxy_backend.new()
    @compiler = Puppet::Parser::Compiler.new(Puppet::Node.new("foo"))
    @scope = Puppet::Parser::Scope.new(@compiler)
    @scope.source = Puppet::Resource::Type.new(:node, :foo)
    @scope.stub(:is_nodescope?).and_return(true)
    @topscope = @scope.compiler.topscope
    @topscope.setvar('hostname', 'foo')
    @scope.parent = @topscope
    roleclasses = ['role::test', 'role::test2']
    roleclasses.each do |roleclass|
      unless @compiler.topscope.find_hostclass(roleclass)
        host_cls = Puppet::Resource::Type.new(:hostclass, roleclass)
        @scope.known_resource_types.add_hostclass(host_cls)
      end
    end
  end

  it "lookup returns the default when no role is defined" do
    expect(
      @backend.lookup('mysql::innodb_threads',@topscope, nil, nil)
    ).to eq(15)
  end

  it "lookup returns the role-specific value if a role is defined" do
    @scope.function_role(['test'])
    expect(
      @backend.lookup('mysql::innodb_threads',@topscope, nil, nil)
    ).to eq(50)
  end

  it "return the host-overridden value for a role-defined variable" do
    @scope.function_role(['test'])
    expect(
      @backend.lookup('admin::groups',@topscope, nil, nil)
    ).to eq(['go-spurs'])
  end

  it "merges values when using an array lookup" do
    @scope.function_role(['test'])
    expect(@backend.lookup('admin::groups', @topscope, nil, :array)).to eq([['go-spurs'],['FooBar']])
  end

end
