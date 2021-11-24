require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::argparse' do
  args1 = {
      'hostname' => 'foo.example.org',
      'port' => 8080,
      'ssl' => true,
  }
  args2 = {
      'first_param' => 'on"e',
      'space' => 'a b',
  }

  it { is_expected.to run.with_params(args1).and_return('--hostname foo.example.org --port 8080 --ssl') }
  it do
    is_expected.to run.with_params(args1, '/foo')
      .and_return('/foo --hostname foo.example.org --port 8080 --ssl')
  end
  it do
    is_expected.to run.with_params(args1.merge('array_arg' => ['foo', 'bar']))
      .and_return('--hostname foo.example.org --port 8080 --ssl --array_arg foo,bar')
  end
  it { is_expected.to run.with_params(args2).and_return('--first_param on\"e --space a\ b') }
end
