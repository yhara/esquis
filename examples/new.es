extern i32 putchar(i32);
class A
  def initialize(@x: Float) { }
end
putchar(A.new(65).x);
