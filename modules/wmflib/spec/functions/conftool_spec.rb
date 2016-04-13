require 'spec_helper'
require 'mocha/test_unit'
require 'json'

describe 'conftool' do

  def gen_conftool_call(selector)
    ['/usr/bin/conftool', '--object-type', 'node', 'select', selector, 'get']
  end

  generate = {}

  before(:each) {
    Puppet::Parser::Functions.newfunction(:generate) {
      |args| generate.call(args)
    }
    generate.stubs(:call).returns('')
  }

  it "should fail if 3 args are given" do
    should run.with_params('a', 'b', 'c').and_raise_error(Puppet::ParseError)
  end

  it "should return an empty list if no result is returned" do
    req = {'name' => 'foo'}
    should run.with_params(req).and_return([])
  end

  it "should return correctly the results" do
    resultset = [
      {"cp1052.eqiad.wmnet" => {"pooled" => "yes",  "weight" => 100}, "tags" => "dc=eqiad,cluster=cache_text,service=varnish-be"},
      {"cp1052.eqiad.wmnet" => {"pooled" => "yes",  "weight" => 1}, "tags" => "dc=eqiad,cluster=cache_text,service=varnish-fe"},
    ]
    retval = resultset.map{ |x| JSON.dump(x) }.join "\n"
    conftool_out = [
      {'name' => 'cp1052.eqiad.wmnet', 'tags' => resultset[0]['tags'], 'value' => resultset[0]['cp1052.eqiad.wmnet']},
      {'name' => 'cp1052.eqiad.wmnet', 'tags' => resultset[1]['tags'], 'value' => resultset[1]['cp1052.eqiad.wmnet']},
    ]
    req = { 'name' => 'cp1052.*', 'service' => 'varnish-..'}
    genargs = gen_conftool_call('name=cp1052.*,service=varnish-..')
    generate.stubs(:call).with(genargs).returns(retval)
    should run.with_params(req).and_return(conftool_out)
  end

  it "should fail if conftool read fails" do
    generate.stubs(:call).raises(Puppet::ParseError, 'something')
    req = {'name' => 'foo'}
    should run.with_params(req).and_raise_error(Puppet::ParseError)
  end

  it "should respond with an error if an empty tag is specified" do
    should run.with_params({}).and_raise_error(Puppet::ParseError)
  end
end
