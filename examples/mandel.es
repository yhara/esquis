extern i32 putchar(i32)

def printdensity(d: Float) -> Void do
  if d > 8 do
    putchar(32)  # ' '
  end
  else if d > 4 do
    putchar(46)  # '.'
  end
  else if d > 2 do
    putchar(43)  # '+'
  end
  else do
    putchar(42) # '*'
  end
end

def mandleconverger(real: Float, imag: Float, iters: Float,
                    creal: Float, cimag: Float) -> Float do
  if iters > 255 || (real*real + imag*imag > 4) do
    return iters
  end
  else do
    return mandleconverger(real*real - imag*imag + creal,
                           2*real*imag + cimag,
                           iters+1, creal, cimag)
  end
end

def mandleconverge(real: Float, imag: Float) -> Float do
  return mandleconverger(real, imag, 0, real, imag)
end

def mandelhelp(xmin: Float, xmax: Float, xstep: Float,
               ymin: Float, ymax: Float, ystep: Float) -> Void do
  for (y: Float ; ymin ... ymax ; ystep) do
    for (x: Float ; xmin ... xmax ; xstep) do
       printdensity(mandleconverge(x,y))
    end
    putchar(10)
  end
end

def mandel(realstart: Float, imagstart: Float,
           realmag: Float, imagmag: Float) -> Void do
  mandelhelp(realstart, realstart+realmag*78, realmag,
             imagstart, imagstart+imagmag*40, imagmag)
end

mandel(-2.3, -1.3, 0.05, 0.07)
