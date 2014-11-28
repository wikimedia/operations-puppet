require 'spec_helper'
require 'hiera/backend/role_backend'
require 'hiera'

describe 'role_backend' do
  before :each do

    @hiera = Hiera.new({:config => 'spec/fixtures/hiera.yaml'})
    Hiera::Config.load('spec/fixtures/hiera.yaml')
    @backend = Hiera::Backend::Role_backend.new()
    @compiler = Puppet::Parser::Compiler.new(Puppet::Node.new("foo"))
    @scope = Puppet::Parser::Scope.new(@compiler)
    @scope.source = Puppet::Resource::Type.new(:node, :foo)
    @scope.stub(:is_nodescope?).and_return(true)
    @topscope = @scope.compiler.topscope
    @scope.parent = @topscope
    roleclasses = ['role::test', 'role::test2']
    roleclasses.each do |roleclass|
      unless @compiler.topscope.find_hostclass(roleclass)
        host_cls = Puppet::Resource::Type.new(:hostclass, roleclass)
        @scope.known_resource_types.add_hostclass(host_cls)
      end
    end
  end

  it "get_path returns the correct path" do
    expect(@backend.get_path('pippo', 'test', 'common', @scope)).to eq("spec/fixtures/hieradata/role/common/test.yaml")
  end

  it "lookup returns nil when no role is defined" do
    expect(@backend.lookup('admin::groups', @topscope, nil, nil)).to eq(nil)
  end

  it "lookup returns a value when a role is defined" do
    @scope.function_role(['test'])
    expect(@backend.lookup('admin::groups', @topscope, nil, nil)).to eq(['FooBar'])
  end

  it "lookup raises an error if conflicting values are given in different roles" do
    @scope.function_role(['test', 'test2'])
    expect {@backend.lookup('admin::groups', @topscope, nil, nil)}.to raise_error(Exception, "Conflicting value for admin::groups found in role test2")
  end

  it "merges values when using an array lookup" do
    @scope.function_role(['test', 'test2'])
    expect(@backend.lookup('admin::groups', @topscope, nil, :array)).to eq([['FooBar'],['FooBar1']])
  end

  it "merges values when using hash lookup" do
    @scope.function_role(['test', 'test2'])
    expect(@backend.lookup('an_hash', @topscope, nil, :hash)).to eq({"test2"=>true, "test3"=>{"another"=>"level"}, "test"=>true})
  end
end
