require 'bundler'
Bundler.require
require_relative 'setup_dll'
require_relative 'ship'
require_relative 'port'
require_relative 'obsticle'

SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720

SHIP_WIDTH = 50
SHIP_HEIGHT = 20
BLUISH = GetColor(0x00949E33)

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
      # @background = LoadTexture('./HarborMaster.png')
      # @texture = LoadTextureFromImage(@background)

      until WindowShouldClose()
        update
        draw
      end

      # UnloadTexture(@background)
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
      @ports.each do |port|
        if port.rect
          if CheckCollisionPointRec(ship.pos, port.rect)
            points = port.dots.map(&:to_a).flatten.pack("F*")
            if CheckCollisionPointPoly(ship.pos, points, port.dots.size)
              if port.color == ship.current_cargo
                ship.start_offloading
              end
            end
          end
        end
      end
    end
  end

  def check_ship(pos)
    @ships.find { |ship| CheckCollisionPointCircle(pos, ship.pos, 10) }
  end

  def draw
    BeginDrawing()
      ClearBackground(BLACK)#RAYWHITE)
      # DrawTexture(@background, 0, 0, WHITE)

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
