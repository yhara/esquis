extern i32 putchar(i32);
class A
  def hi(x: Float) -> Float { putchar(x + 65); }
end
A.new().hi(0);
