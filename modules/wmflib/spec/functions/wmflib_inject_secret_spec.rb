require 'spec_helper'

describe 'wmflib::inject_secret' do
  context 'existing secret' do
    before(:each) do
      Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |args|
        "Secret #{args[0]} found!"
      }
    end

    {
      inject: ['secret(test)', 'Secret test found!'],
      noop: ['secret(malformed', 'secret(malformed'],
      mixed: [
        {a: [1, 2, true, 'secret(test)'], b: 'secret(test2)'},
        {a: [1, 2, true, 'Secret test found!'], b: 'Secret test2 found!'}
      ]
    }.each do |k, (input, expected)|
      context k do
        it { is_expected.to run.with_params(input).and_return(expected)}
      end
    end
  end
  context 'inexistent secret' do
    before(:each) do
      Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |args|
        fail(ArgumentError, "secret(): invalid secret #{args[0]}")
      }
    end
    it { is_expected.to run.with_params('secret(test)').and_raise_error(ArgumentError)}
  end
end
