require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::argparse' do
  args = {
      hostname: 'foo.example.org',
      port: 8080,
      ssl: true,
  }

  it { is_expected.to run.with_params(args).and_return("--hostname foo.example.org --port 8080 --ssl") }
  it do
    is_expected.to run.with_params(args, '/foo')
      .and_return("/foo --hostname foo.example.org --port 8080 --ssl")
  end
  it { is_expected.to run.with_params(args.merge(array_arg: ['foo', 'bar']))
    .and_return("--hostname foo.example.org --port 8080 --ssl --array_arg foo,bar") }
end
