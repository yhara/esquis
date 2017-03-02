require 'spec_helper'

describe "Esquis" do
  def to_ll(src)
    Esquis::Ast.reset
    ast = Esquis::Parser.new.parse(src)
    ast.to_ll_str
  end

  context "syntax" do
    it "should check duplicated toplevel func" do
      expect {
        to_ll(<<~EOD)
          extern i32 putchar(i32)
          def putchar(x: Float, y: Float) -> Float do return x end
        EOD
      }.to raise_error(Esquis::Ast::DuplicatedDefinition)
    end

    it "should check duplicated param names" do
      expect {
        to_ll(<<~EOD)
          def putchar(x: Float, x: Float) -> Float do return x end
        EOD
      }.to raise_error(Esquis::Ast::DuplicatedParamName)
    end

    it "should check return in main" do
      expect {
        to_ll(<<~EOD)
          return 1
        EOD
      }.to raise_error(Esquis::Ast::MisplacedReturn)
    end
  end

  context "typing" do
    context "method definition" do
      it "should check return type" do
        expect {
          to_ll(<<~EOD)
            class A
              def foo() -> Float do
                1 == 2
              end
            end
          EOD
        }.to raise_error(Esquis::Ast::TypeMismatch)
      end

      it "should pass recursive method" do
        expect {
          to_ll(<<~EOD)
            class A
              def foo(x: Float) -> Float do A.new().foo(x) end
            end
          EOD
        }.not_to raise_error
      end
    end

    context "method/function call" do
      it "should check arity when calling toplevel func" do
        expect {
          to_ll(<<~EOD)
            def foo(x: Float) -> Float do 1 end
            foo(1, 2)
          EOD
        }.to raise_error(Esquis::Ast::ArityMismatch)
      end

      it "should check arg types when calling toplevel func" do
        expect {
          to_ll(<<~EOD)
            def foo(x: Float) -> Float do 1 end
            foo(1 == 2)
          EOD
        }.to raise_error(Esquis::Ast::TypeMismatch)
      end

      it "should pass recursive toplevel func" do
        expect {
          to_ll(<<~EOD)
            def foo(x: Float) -> Float do foo(x) end
          EOD
        }.not_to raise_error
      end

      it "should check arity of new" do
        expect {
          to_ll(<<~EOD)
            class A
              def initialize() do 1 end
            end
            A.new(1)
          EOD
        }.to raise_error(Esquis::Ast::ArityMismatch)
      end

      it "should check arg types of new" do
        expect {
          to_ll(<<~EOD)
            class A
              def initialize(x: Float) do 1 end
            end
            A.new(1 == 1)
          EOD
        }.to raise_error(Esquis::Ast::TypeMismatch)
      end

      it "should check arity of method call" do
        expect {
          to_ll(<<~EOD)
            class A
              def foo() -> Float do 1 end
            end
            A.new().foo(1)
          EOD
        }.to raise_error(Esquis::Ast::ArityMismatch)
      end

      it "should check arg types of method call" do
        expect {
          to_ll(<<~EOD)
            class A
              def foo(x: Float) -> Float do 1 end
            end
            A.new().foo(1 == 1)
          EOD
        }.to raise_error(Esquis::Ast::TypeMismatch)
      end

      it "should allow passing Float to double extern arg" do
        expect {
          to_ll(<<~EOD)
            extern double sqrt(double)
            sqrt(56.0)
          EOD
        }.not_to raise_error
      end

      it "should allow return double instead of Float" do
        expect {
          to_ll(<<~EOD)
            extern double sqrt(double)
            def foo() -> Float do sqrt(1) end
          EOD
        }.not_to raise_error
      end
    end

    it "should check condition of if-stmt is Bool" do
      expect {
        to_ll(<<~EOD)
          if 1 do 2 end
        EOD
      }.to raise_error(Esquis::Ast::TypeMismatch)

      expect {
        to_ll(<<~EOD)
          if 1 == 1 do 2 end
        EOD
      }.not_to raise_error
    end
  end
end
