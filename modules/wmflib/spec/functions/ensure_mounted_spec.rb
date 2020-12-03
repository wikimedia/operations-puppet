require_relative '../../../../rake_modules/spec_helper'

describe "ensure_mounted" do
  it "should exist" do
    expect(Puppet::Parser::Functions.function("ensure_mounted")).to eq("function_ensure_mounted")
  end

  it "should raise a ParseError if there are less than 1 arguments" do
    is_expected.to run.with_params.and_raise_error(ArgumentError)
  end

  it "should raise a ParseError if there are more than 1 arguments" do
    is_expected.to run.with_params('a', 'b').and_raise_error(ArgumentError)
  end

  it "should return 'mounted' for param 'present'" do
    expect(scope.function_ensure_mounted(['present'])).to eq('mounted')
  end

  it "should return 'mounted' for param 'true'" do
    expect(scope.function_ensure_mounted([true])).to eq('mounted')
  end

  it "should return 'absent' for param 'absent'" do
    expect(scope.function_ensure_mounted(['absent'])).to eq('absent')
  end

  it "should return 'false' for param 'false'" do
    expect(scope.function_ensure_mounted([false])).to eq(false)
  end
end
