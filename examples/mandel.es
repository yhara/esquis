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
  for (y ; ymin ... ymax ; ystep) {
    for (x ; xmin ... xmax ; xstep) {
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
