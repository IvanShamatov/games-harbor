class Ship
  attr_reader :rect, :current_cargo
  attr_accessor :path, :pos
  SPEED = 0.5
  OFFLOAD = 5

  COLORS = {
    purple: PURPLE,
    gold: GOLD,
    red: RED
  }


  def initialize(pos)
    @path = []
    @future_path = []
    @pos = pos
    @vel = Vector2Scale(Vector2Normalize(Vector2Subtract(Vector2.create(SCREEN_WIDTH/2.0, SCREEN_HEIGHT/2.0), @pos)), SPEED)
    @state = :idle
    @cargo = [:purple, :gold, :red].shuffle
    @current_cargo = @cargo.pop
    @offloading = 0
  end

  def update
    if @state == :idle
      @pos = Vector2Add(@pos, @vel)
    end

    if @path.size > 0 && @state == :idle
      @state = :running
      @goal = @path.shift
    end

    if @state == :running
      @vel = Vector2Scale(Vector2Normalize(Vector2Subtract(@goal, @pos)), SPEED)
      @pos = Vector2MoveTowards(@pos, @goal, SPEED)

      if CheckCollisionPointCircle(@goal, @pos, 1)
        if !@path.empty?
          @goal = @path.shift
        else
          @state = :idle
        end
      end
    end

    if @state == :offloading
      @offloading =+ GetFrameTime()
      @vel = Vector2Zero()

      if @offloading > OFFLOAD
        @state = :idle
        @current_cargo = @cargo.pop unless @cargo.nil?
        @offloading = 0
      end
    end
  end

  def stop_path
    @path = @future_path.dup
    @future_path = []
    @continue = false
  end

  def start_offloading
    @state = :offloading
  end

  def continue(point)
    unless @continue
      @continue = true
      @future_path = []
    end
    @future_path << point
  end

  def current_color
    @cargo.nil? ? WHITE : COLORS[@current_cargo]
  end

  def draw
    if [@pos, @goal, *@path].size > 4
      @buf = [@pos, @goal, *@path].map(&:to_a).flatten.pack("F*")
      DrawSplineBasis(@buf, @path.size + 2, 3, GRAY)
    end

    if @future_path.size > 4
      @buf = @future_path.map(&:to_a).flatten.pack("F*")
      DrawSplineBasis(@buf, @future_path.size, 3, GREEN)
    end
    # DrawRectanglePro(@rect, Vector2Zero(), 10, RED)
    DrawCircleV(@pos, 15, current_color)
  end
end
