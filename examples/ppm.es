extern i32 putchar(i32);

# P3\n
putchar(80); putd(3); putchar(10);
# W H\n
putd(256); putchar(32); putd(256); putchar(10);
# D
putd(255); putchar(10);

# Output a ppm image
for (x: Float ; 0 ... 256 ; 1) {
  for (y: Float ; 0 ... 256 ; 1) {
     putd(x); putchar(32); putd(y); putchar(32); putd(0); putchar(10);
  }
}
