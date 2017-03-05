require 'spec_helper'

describe Esquis do
  def run(src)
    Esquis::Ast.reset
    return Esquis.run(src, capture: true)
  end

  it 'should parse example program' do
    expect {
      ast = Esquis::Parser.new.parse(File.read("#{__dir__}/../examples/mandel.es"))
      ast.to_ll_str
    }.not_to raise_error
  end

  describe '.run' do
    it 'should run esquis program (with llc)' do
      out = run(<<~EOD)
        extern i32 putchar(i32)
        putchar(65)
      EOD
      expect(out).to eq("A")
    end
  end

  describe 'programs' do
    it 'defclass' do
      src = <<~EOD
        extern i32 putchar(i32)
        class A
          def hi(x: Float) -> Void; putchar(x + 65); end
        end
        A.new().hi(0)
      EOD
      expect(run(src)).to eq("A")
    end

    it 'defun' do
      src = <<~EOD
        extern i32 putchar(i32)
        def eq(x: Float, y: Float) -> Bool; return x == y; end
        if eq(1, 1); putchar(65); end
      EOD
      expect(run(src)).to eq("A")
    end

    it '+' do
      src = "extern i32 putchar(i32); putchar(60 + 5)"
      expect(run(src)).to eq("A")
    end

    it '-' do
      src = "extern i32 putchar(i32); putchar(70 - 5)"
      expect(run(src)).to eq("A")
    end

    it '*' do
      src = "extern i32 putchar(i32); putchar(13 * 5)"
      expect(run(src)).to eq("A")
    end

    it '/' do
      src = "extern i32 putchar(i32); putchar(157 / 2.41)"
      expect(run(src)).to eq("A")
    end

    it '==' do
      src = "extern i32 putchar(i32); if 1 == 1; putchar(65); end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if 1 == 2; putchar(65); end"
      expect(run(src)).to eq("")
    end

    it '>' do
      src = "extern i32 putchar(i32); if 2 > 1; putchar(65); end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if 1 > 2; putchar(65); end"
      expect(run(src)).to eq("")
    end

    it '>=' do
      src = "extern i32 putchar(i32); if 1 >= 1; putchar(65); end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if 1 >= 2; putchar(65); end"
      expect(run(src)).to eq("")
    end

    it '<' do
      src = "extern i32 putchar(i32); if 1 < 2; putchar(65); end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if 2 < 1; putchar(65); end"
      expect(run(src)).to eq("")
    end

    it '<=' do
      src = "extern i32 putchar(i32); if 1 <= 1; putchar(65); end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if 2 <= 1; putchar(65); end"
      expect(run(src)).to eq("")
    end

    it '!=' do
      src = "extern i32 putchar(i32); if 1 != 2; putchar(65); end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if 1 != 1; putchar(65); end"
      expect(run(src)).to eq("")
    end

    it '&&' do
      src = "extern i32 putchar(i32); if 1 == 1 && 2 == 2; putchar(65); end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if 1 == 1 && 2 == 0; putchar(65); end"
      expect(run(src)).to eq("")
    end

    it '||' do
      src = "extern i32 putchar(i32); if 1 == 0 || 2 == 2; putchar(65); end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if 1 == 0 || 2 == 0; putchar(65); end"
      expect(run(src)).to eq("")
    end

    it 'unary -' do
      src = "extern i32 putchar(i32); putchar(-(-65))"
      expect(run(src)).to eq("A")
    end

    describe 'if' do
      it 'has value' do
        src = <<-EOD
          extern i32 putchar(i32)
          putchar(if 1 == 2; 65; else 66; end)
        EOD
        expect(run(src)).to eq("B")
      end

      it 'one-sided' do
        src = <<-EOD
          extern i32 putchar(i32)
          if 1 == 1; putchar(65); end
        EOD
        expect(run(src)).to eq("A")
      end
    end

    it 'for' do
      src = <<-EOD
        extern i32 putchar(i32)
        for (x: Int; 65 ... 70 ; 2)
          putchar(x)
        end
      EOD
      expect(run(src)).to eq("ACE")
    end

    context 'lvar' do
      it 'assignment' do
        src = <<-EOD
          extern i32 putchar(i32)
          a = 60 + 5
          putchar(a)
        EOD
        expect(run(src)).to eq("A")
      end
    end

    context 'ivar' do
      it 'reference with name' do
        src = <<~EOD
          extern i32 putchar(i32)
          class A
            def initialize(@x: Float); end
            def foo() -> Float; return @x; end
          end
          putchar(A.new(65).foo())
        EOD
        expect(run(src)).to eq("A")
      end

      it 'update value' do
        src = <<~EOD
          extern i32 putchar(i32)
          class A
            def initialize(@x: Float); end
            def inc(d: Float) -> Void; @x = @x + d; end
          end
          a = A.new(65)
          a.inc(1)
          putchar(a.x)
        EOD
        expect(run(src)).to eq("B")
      end

      it 'reference with accessor' do
        src = <<~EOD
          extern i32 putchar(i32)
          class A
            def initialize(@x: Float); end
          end
          putchar(A.new(65).x)
        EOD
        expect(run(src)).to eq("A")
      end
    end
  end
end
