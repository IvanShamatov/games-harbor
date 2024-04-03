require 'bundler'
Bundler.require
require_relative 'setup_dll'

SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720

SHIP_WIDTH = 50
SHIP_HEIGHT = 20


class Ship
  attr_reader :rect
  attr_accessor :path, :pos
  SPEED = 0.5
  OFFLOAD = 5

  def initialize(pos)
    @path = []
    @future_path = []
    @pos = pos
    @vel = Vector2Scale(Vector2Normalize(Vector2Subtract(Vector2.create(SCREEN_WIDTH/2.0, SCREEN_HEIGHT/2.0), @pos)), SPEED)
    @state = :idle
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

      # bool CheckCollisionPointPoly(Vector2 point, Vector2 *points, int pointCount);
    end

    if @state == :offloading
      @offloading =+ GetFrameTime()

      if @offloading > OFFLOAD
        @vel = Vector2Zero()
        @state = :idle
      end
    end
  end

  def stop_path
    @path = @future_path.dup
    @future_path = []
    @continue = false
  end

  def continue(point)
    unless @continue
      @continue = true
      @future_path = []
    end
    @future_path << point
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
    DrawCircleV(@pos, 15, WHITE)
  end
end


BLUISH = GetColor(0x00949E33)

class Port
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
    DrawRectangleLinesEx(@rect, 3, LIME) if @rect
    @dots.each_with_index do |point, i|
      DrawCircleV(point, 5, GREEN)
      DrawLineEx(point, @dots[i-1], 3, GREEN);
    end
  end
end

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


class Game
  include Raylib

  def initialize
    @obsticles = []
    @current_obsticle = Obsticle.new
    @ports = []
    @current_port = Port.new
    @ships = []
    5.times do
      pos = Vector2.create(rand(SCREEN_WIDTH), rand(SCREEN_HEIGHT))
      ship = Ship.new(pos)
      # puts "(#{ship.rect.x}, #{ship.rect.y}, #{ship.rect.width}, #{ship.rect.height})"
      @ships << ship

    end
    @active_ship = nil
  end

  def run
    SetTargetFPS(60)
    SetConfigFlags(FLAG_MSAA_4X_HINT)

    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Harbor Master")
      @background = LoadTexture('./HarborMaster.png')
      # @texture = LoadTextureFromImage(@background)

      until WindowShouldClose()
        update
        draw
      end

      UnloadTexture(@background)
      # UnloadImage(@background)
    CloseWindow()
  end

  def update
    if IsKeyPressed(KEY_E)
      @mode = :editor
    end

    if IsKeyPressed(KEY_G)
      @mode = :game
    end

    if IsKeyPressed(KEY_P) && @mode == :editor
      @adding = :port
      if @current_port
        @ports << @current_port
      end
      @current_port = Port.new
    end

    if IsKeyPressed(KEY_O) && @mode == :editor

      @adding = :obsticle
      if @current_obsticle
        @obsticles << @current_obsticle
      end
      @current_obsticle = Obsticle.new
    end

    if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) && @mode == :editor
      case @adding
      when :port
        @current_port.add(GetMousePosition())
      when :obsticle
        @current_obsticle.add(GetMousePosition())
      end
    end

    if IsMouseButtonDown(MOUSE_BUTTON_LEFT)
      pos = GetMousePosition()
      ship = check_ship(pos)

      @active_ship = ship if ship
      @active_ship.continue(pos) if @active_ship
    end

    if IsMouseButtonReleased(MOUSE_BUTTON_LEFT)
      @active_ship.stop_path if @active_ship
      @active_ship = nil
    end

    @ships.each(&:update) unless @mode == :editor
    @ships.each do |ship|
      # check obsticle collisions

    end
  end

  def check_ship(pos)
    @ships.find { |ship| CheckCollisionPointCircle(pos, ship.pos, 10) }
  end

  def draw
    BeginDrawing()
      ClearBackground(RAYWHITE)
      DrawTexture(@background, 0, 0, WHITE)

      @ships.each(&:draw)

      @ports.each(&:draw)
      @current_port.draw

      @obsticles.each(&:draw)
      @current_obsticle.draw
      # @active_ship.

      # current_buffer = @current_path.map(&:to_a).flatten.pack("F*")
      # DrawSplineBasis(current_buffer, @current_path.size, 3, RED)

      # @paths.each do |path|
      #   points_buffer = path.map(&:to_a).flatten.pack("F*")
      #   DrawSplineBasis(points_buffer, path.size, 3, WHITE)
      # end
      DrawFPS(50, 50)
    EndDrawing()
  end
end

Game.new.run
