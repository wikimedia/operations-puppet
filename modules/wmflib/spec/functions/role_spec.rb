require 'spec_helper'
describe 'role' do

  before :each do
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

  it "should be called with one parameter" do
    should run.and_raise_error(ArgumentError)
  end
  it "throws error if called outside of the node scope" do
    should run.with_params('cache::text').and_raise_error(Puppet::ParseError)
  end

  it "throws error if called on a non-existing role" do
    expect { @scope.function_role(['foo::bar']) }.to raise_error(Puppet::ParseError)
  end

  it "includes the role class" do
    expect { @scope.function_role(['test']) }.to_not raise_error()
  end

  it "raises an error when called more than once in a scope" do
    @scope.function_role(['test2'])
    expect { @scope.function_role(['test']) }.to raise_error(Puppet::ParseError)
  end

  it "adds the keys to the top-scope variable" do
    @scope.function_role(['test', 'test2'])
    expect(@topscope.lookupvar('_roles')).to eq({'test' => true, 'test2' => true})
  end

  it "includes the role classes" do
    @scope.function_role(['test'])
    expect(@scope.find_hostclass('role::test')).to be_an_instance_of(Puppet::Resource::Type)
  end
end
