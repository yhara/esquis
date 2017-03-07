# Esquis port of http://qiita.com/doxas/items/477fda867da467116f8d
extern i32 putchar(i32);
extern double sqrt(double); 
extern double fabs(double); 
extern double sin(double); 
extern double cos(double); 

IMAGE_WIDTH = 700
IMAGE_HEIGHT = 700
IMAGE_DEPTH = 256
EPS = 0.0001
MAX_REF = 4

def clamp(t: Float, min: Float, max: Float) -> Float
  if t < min
    min
  elsif t > max
    max
  else
    t
  end
end

class Vec
  def initialize(@x: Float, @y: Float, @z: Float); end

  def vadd(b: Vec) -> Vec
    Vec.new(@x + b.x, @y + b.y, @z + b.z)
  end

  def vsub(b: Vec) -> Vec
    Vec.new(@x - b.x, @y - b.y, @z - b.z)
  end

  def vmul(t: Float) -> Vec
    Vec.new(@x * t, @y * t, @z * t)
  end

  def vmulti(b: Vec) -> Vec
    Vec.new(@x * b.x, @y * b.y, @z * b.z)
  end

  def vdot(b: Vec) -> Float
    @x * b.x + @y * b.y + @z * b.z
  end

  def vcross(b: Vec) -> Vec
    Vec.new(@y * b.z - @z * b.y,
            @z * b.x - @x * b.z,
            @x * b.y - @y * b.x)
  end
 
  def vlength -> Float
    sqrt(@x * @x + @y * @y + @z * @z)
  end
 
  def vnormalize! -> Vec
    len = self.vlength()
    if len > 0.00000000000000001
      r_len = 1.0 / len
      @x = @x * r_len
      @y = @y * r_len
      @z = @z * r_len
    end
    self
  end

  def reflect(normal: Vec) -> Vec
    self.vadd(normal.vmul(-2 * normal.vdot(self)))
  end
end

LIGHT = Vec.new(0.577, 0.577, 0.577)

class Ray
  def initialize(@origin: Vec, @dir: Vec); end
end

class Isect
  def initialize(@hit: Float, @hit_point: Vec, @normal: Vec,
                 @color: Vec, @distance: Float, @ray_dir: Vec); end
end

class Sphere
  def initialize(@radius: Float, @position: Vec, @color: Vec); end

  def intersect!(ray: Ray, isect: Isect) -> Void
    rs = ray.origin.vsub(@position)
    b = rs.vdot(ray.dir)
    c = rs.vdot(rs) - @radius * @radius
    d = b * b - c
    if d > 0 && (t = -b - sqrt(d)) > EPS && t < isect.distance
      isect.hit_point = ray.origin.vadd(ray.dir.vmul(t))
      isect.normal = isect.hit_point.vsub(@position).vnormalize!
      isect.color = @color.vmul(clamp(LIGHT.vdot(isect.normal), 0.1, 1.0))
      isect.distance = t
      isect.hit = isect.hit + 1
      isect.ray_dir = ray.dir
    end
  end
end

class Plane
  def initialize(@position: Vec, @normal: Vec, @color: Vec); end

  def intersect!(ray: Ray, isect: Isect) -> Void
    d = -(@position.vdot(@normal))
    v = ray.dir.vdot(@normal)
    t = -(ray.origin.vdot(@normal) + d) / v
    if t > EPS && t < isect.distance
      isect.hit_point = ray.origin.vadd(ray.dir.vmul(t))
      isect.normal = @normal
      d2 = clamp(LIGHT.vdot(isect.normal), 0.1, 1.0)
      m = isect.hit_point.x % 2
      n = isect.hit_point.z % 2
      d3 = if (m > 1 && n > 1) || (m < 1 && n < 1)
             d2 * 0.5
           else
             d2
           end
      abs = fabs(isect.hit_point.z)
      f = 1.0 - (if abs < 25.0; abs; else 25.0; end) * 0.04
      isect.color = @color.vmul(d3 * f)
      isect.distance = t
      isect.hit = isect.hit + 1
      isect.ray_dir = ray.dir
    end
  end
end

## t: 0 ~ 1
def color(t: Float) -> Float
  ret = IMAGE_DEPTH * clamp(t, 0, 1)
  return if ret == IMAGE_DEPTH; IMAGE_DEPTH-1; else ret; end
end

def print_col(c: Vec) -> Void
  putd(color(c.x)); putchar(32)
  putd(color(c.y)); putchar(32)
  putd(color(c.z)); putchar(10)
end

PLANE = Plane.new(Vec.new(0, -1, 0), Vec.new(0, 1, 0), Vec.new(1, 1, 1))
T = 0
SPHERE1 = Sphere.new(0.5, Vec.new( 0.0, -0.5, sin(0)), Vec.new(1, 0, 0))
SPHERE2 = Sphere.new(1.0, Vec.new( 2.0,  0.0, cos(T*0.666)), Vec.new(0, 1, 0))
SPHERE3 = Sphere.new(1.5, Vec.new(-2.0,  0.5, cos(T*0.333)), Vec.new(0, 0, 1))

def intersect!(ray: Ray, i: Isect) -> Void
  SPHERE1.intersect!(ray, i) 
  SPHERE2.intersect!(ray, i) 
  SPHERE3.intersect!(ray, i) 
  PLANE.intersect!(ray, i)
end

# P3\n
putchar(80); putd(3); putchar(10)
# W H\n
putd(IMAGE_WIDTH); putchar(32); putd(IMAGE_HEIGHT); putchar(10)
# D
putd(255); putchar(10)

for (row: Float ; 0 ... IMAGE_HEIGHT ; 1)
  for (col: Float ; 0 ... IMAGE_WIDTH ; 1)
    x = col / (IMAGE_WIDTH / 2) - 1.0
    y = (IMAGE_HEIGHT-row) / (IMAGE_HEIGHT / 2) - 1.0

    ray = Ray.new(Vec.new(0.0, 2.0, 6.0),
                  Vec.new(x, y, -1.0).vnormalize!)
    i = Isect.new(0, Vec.new(0, 0, 0), Vec.new(0, 0, 0), Vec.new(0, 0, 0),
                  1000000000000000000000000000000, Vec.new(0, 0, 0))
    intersect!(ray, i)
    if i.hit > 0
      var dest_col = i.color
      var temp_col = Vec.new(1, 1, 1).vmulti(i.color)
      for (j: Float; 1...MAX_REF; 1)
        q = Ray.new(i.hit_point.vadd(i.normal.vmul(EPS)),
                    i.ray_dir.reflect(i.normal))
        intersect!(q, i)
        if i.hit > j
          dest_col = dest_col.vadd(temp_col.vmulti(i.color))
          temp_col = temp_col.vmulti(i.color)
        end
      end
      print_col(dest_col)
    else
      print_col(Vec.new(ray.dir.y, ray.dir.y, ray.dir.y))
    end
  end
end
