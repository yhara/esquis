extern i32 putchar(i32)

def printdensity(d: Float) -> Void
  if d > 8
    putchar(32)  # ' '
  elsif d > 4
    putchar(46)  # '.'
  elsif d > 2
    putchar(43)  # '+'
  else
    putchar(42) # '*'
  end
end

def mandleconverger(real: Float, imag: Float, iters: Float,
                    creal: Float, cimag: Float) -> Float
  if iters > 255 || (real*real + imag*imag > 4)
    return iters
  else
    return mandleconverger(real*real - imag*imag + creal,
                           2*real*imag + cimag,
                           iters+1, creal, cimag)
  end
end

def mandleconverge(real: Float, imag: Float) -> Float
  return mandleconverger(real, imag, 0, real, imag)
end

def mandelhelp(xmin: Float, xmax: Float, xstep: Float,
               ymin: Float, ymax: Float, ystep: Float) -> Void
  for (y: Float ; ymin ... ymax ; ystep)
    for (x: Float ; xmin ... xmax ; xstep)
       printdensity(mandleconverge(x,y))
    end
    putchar(10)
  end
end

def mandel(realstart: Float, imagstart: Float,
           realmag: Float, imagmag: Float) -> Void
  mandelhelp(realstart, realstart+realmag*78, realmag,
             imagstart, imagstart+imagmag*40, imagmag)
end

mandel(-2.3, -1.3, 0.05, 0.07)
