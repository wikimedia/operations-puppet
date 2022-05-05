require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::encode_www_form' do
  args1 = {
      'hostname' => 'foo.example.org',
      'port' => 8080,
      'ssl' => true,
  }
  args2 = {
      'first_param' => 'on"e',
      'space' => 'a b',
  }

  it do
    is_expected.to run.with_params(args1)
      .and_return('hostname=foo.example.org&port=8080&ssl=true')
  end
  it do
    is_expected.to run.with_params(args1.merge('array_arg' => ['foo', 'bar']))
      .and_return('hostname=foo.example.org&port=8080&ssl=true&array_arg=foo&array_arg=bar')
  end
  it do
    is_expected.to run.with_params(args2)
      .and_return('first_param=on%22e&space=a+b')
  end
end
