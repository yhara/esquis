require 'spec_helper'

MANDEL = <<EOD
extern i32 putchar(i32);

def printdensity(d: Float) -> Float {
  if d > 8 {
    putchar(32);  # ' '
  }
  else if d > 4 {
    putchar(46);  # '.'
  }
  else if d > 2 {
    putchar(43);  # '+'
  }
  else {
    putchar(42); # '*'
  }
}

def mandleconverger(real: Float, imag: Float, iters: Float,
                    creal: Float, cimag: Float) -> Float {
  if iters > 255 || (real*real + imag*imag > 4) {
    return iters;
  }
  else {
    return mandleconverger(real*real - imag*imag + creal,
                           2*real*imag + cimag,
                           iters+1, creal, cimag);
  }
}

def mandleconverge(real: Float, imag: Float) -> Float {
  return mandleconverger(real, imag, 0, real, imag);
}

def mandelhelp(xmin: Float, xmax: Float, xstep: Float,
               ymin: Float, ymax: Float, ystep: Float) -> Float {
  for (y: Float ; ymin ... ymax ; ystep) {
    for (x: Float ; xmin ... xmax ; xstep) {
       printdensity(mandleconverge(x,y));
    }
    putchar(10);
  }
}

def mandel(realstart: Float, imagstart: Float,
           realmag: Float, imagmag: Float) -> Float {
  return mandelhelp(realstart, realstart+realmag*78, realmag,
                    imagstart, imagstart+imagmag*40, imagmag);
}

mandel(-2.3, -1.3, 0.05, 0.07);
EOD

describe Esquis do
  def run(src)
    Esquis::Ast.reset
    return Esquis.run(src, capture: true)
  end

  it 'should parse example program' do
    ast = Esquis::Parser.new.parse(MANDEL)
    expect(ast).to be_kind_of(Esquis::Ast::Node)
  end

  describe '.run' do
    it 'should run esquis program (with llc)' do
      out = run(<<~EOD)
        extern i32 putchar(i32);
        putchar(65);
      EOD
      expect(out).to eq("A")
    end
  end

  describe 'programs' do
    it 'defun' do
      src = <<-EOD
        extern i32 putchar(i32);
        def add(x: Float, y: Float) -> Float { return x + y; }
        putchar(add(60, 5));
      EOD
      expect(run(src)).to eq("A")
    end

    it '+' do
      src = "extern i32 putchar(i32); putchar(60 + 5);"
      expect(run(src)).to eq("A")
    end

    it '-' do
      src = "extern i32 putchar(i32); putchar(70 - 5);"
      expect(run(src)).to eq("A")
    end

    it '*' do
      src = "extern i32 putchar(i32); putchar(13 * 5);"
      expect(run(src)).to eq("A")
    end

    it '/' do
      src = "extern i32 putchar(i32); putchar(157 / 2.41);"
      expect(run(src)).to eq("A")
    end

    it '==' do
      src = "extern i32 putchar(i32); if (1 == 1) { putchar(65); }"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if (1 == 2) { putchar(65); }"
      expect(run(src)).to eq("")
    end

    it '>' do
      src = "extern i32 putchar(i32); if (2 > 1) { putchar(65); }"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if (1 > 2) { putchar(65); }"
      expect(run(src)).to eq("")
    end

    it '>=' do
      src = "extern i32 putchar(i32); if (1 >= 1) { putchar(65); }"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if (1 >= 2) { putchar(65); }"
      expect(run(src)).to eq("")
    end

    it '<' do
      src = "extern i32 putchar(i32); if (1 < 2) { putchar(65); }"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if (2 < 1) { putchar(65); }"
      expect(run(src)).to eq("")
    end

    it '<=' do
      src = "extern i32 putchar(i32); if (1 <= 1) { putchar(65); }"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if (2 <= 1) { putchar(65); }"
      expect(run(src)).to eq("")
    end

    it '!=' do
      src = "extern i32 putchar(i32); if (1 != 2) { putchar(65); }"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if (1 != 1) { putchar(65); }"
      expect(run(src)).to eq("")
    end

    it '&&' do
      src = "extern i32 putchar(i32); if (1 == 1 && 2 == 2) { putchar(65); }"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if (1 == 1 && 2 == 0) { putchar(65); }"
      expect(run(src)).to eq("")
    end

    it '||' do
      src = "extern i32 putchar(i32); if (1 == 0 || 2 == 2) { putchar(65); }"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32); if (1 == 0 || 2 == 0) { putchar(65); }"
      expect(run(src)).to eq("")
    end

    it 'unary -' do
      src = "extern i32 putchar(i32); putchar(-(-65));"
      expect(run(src)).to eq("A")
    end

    it 'for' do
      src = <<-EOD
        extern i32 putchar(i32);
        for (x: Int; 65 ... 70 ; 2) {
          putchar(x);
        }
      EOD
      expect(run(src)).to eq("ACE")
    end
  end
end
