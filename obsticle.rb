class Obsticle
  attr_reader :rect

  def initialize
    @dots = []
  end

  def add(pos)
    @dots << pos
    update_boundaries(pos)
  end

  def update_boundaries(pos)
    return if @dots.size < 2 # we cannot make rectangle if there are less then 2 dots

    if @dots.size == 2
      f, s = @dots
      @rect = Rectangle.create([f.x, s.x].min, [f.y, s.y].min, (f.x-s.x).abs, (f.y-s.y).abs)
    end

    return if @rect && CheckCollisionPointRec(pos, @rect) # skip if dot is inside current rect

    if pos.x <= @rect.x
      new_x = pos.x
      new_w = (@rect.x - pos.x) + @rect.width
    end

    if pos.y <= @rect.y
      new_y = pos.y
      new_h = @rect.y - pos.y + @rect.height
    end

    if pos.x >= @rect.x + @rect.width
      new_w = pos.x - @rect.x
    end

    if pos.y >= @rect.y + @rect.height
      new_h = pos.y - @rect.y
    end

    @rect.x = new_x if new_x
    @rect.y = new_y if new_y
    @rect.width = new_w if new_w
    @rect.height = new_h if new_h
  end

  def draw
    DrawRectangleLinesEx(@rect, 3, PINK) if @rect
    @dots.each_with_index do |point, i|
      DrawCircleV(point, 5, RED)
      DrawLineEx(point, @dots[i-1], 3, RED);
    end
  end
end
