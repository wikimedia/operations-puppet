require_relative '../../../../rake_modules/spec_helper'

describe "hash_select_re" do
  it "should exist" do
    expect(Puppet::Parser::Functions.function("hash_select_re")).to eq("function_hash_select_re")
  end

  it "should raise a ParseError if there are less than 2 arguments" do
    is_expected.to run.with_params('a').and_raise_error(Puppet::ParseError)
  end

  it "should raise a ParseError if there are more than 2 arguments" do
    is_expected.to run.with_params('a', 'b', 'c').and_raise_error(Puppet::ParseError)
  end

  it "should select the right keys (simple)" do
    expect(
      scope.function_hash_select_re(['^a', {'abc' => 1, 'def' => 2, 'asdf' => 3}])
    ).to eq({'abc' => 1, 'asdf' => 3})
  end

  it "should select the right keys (neg lookahead)" do
    expect(
      scope.function_hash_select_re(['^(?!a)', {'abc' => 1, 'def' => 2, 'asdf' => 3}])
    ).to eq({'def' => 2})
  end
end
