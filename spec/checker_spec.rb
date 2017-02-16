require 'spec_helper'

describe "Esquis" do
  def to_ll(src)
    ast = Esquis::Parser.new.parse(src)
    ast.to_ll_str
  end

  context "syntax" do
    it "should check duplicated toplevel func" do
      expect {
        to_ll(<<~EOD)
          extern i32 putchar(i32);
          def putchar(x: Float, y: Float) -> Float { return x; }
        EOD
      }.to raise_error(Esquis::Ast::DuplicatedDefinition)
    end

    it "should check duplicated param names" do
      expect {
        to_ll(<<~EOD)
          def putchar(x: Float, x: Float) -> Float { return x; }
        EOD
      }.to raise_error(Esquis::Ast::DuplicatedParamName)
    end

    it "should check return in main" do
      expect {
        to_ll(<<~EOD)
          return 1;
        EOD
      }.to raise_error(Esquis::Ast::MisplacedReturn)
    end
  end

  context "typing" do
    it "should check arity on calling toplevel func"
    it "should check arity of method call"
  end
end
