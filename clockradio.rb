#! /usr/bin/env ruby

# Raspberry Pi clock radio

require 'i2c'

class ClockRadio

  attr_reader :i2c
  attr_accessor :i2c_addr

  SEVEN_SEGMENT_MAP = {
    ' ' => [ 0x00, 0x00 ],
    '0' => [ 0x5f, 0x00 ],
    '1' => [ 0x0c, 0x00 ],
    '2' => [ 0x3b, 0x00 ],
    '3' => [ 0x3e, 0x00 ],
    '4' => [ 0x6c, 0x00 ],
    '5' => [ 0x76, 0x00 ],
    '6' => [ 0x77, 0x00 ],
    '7' => [ 0x1c, 0x00 ],
    '8' => [ 0x7f, 0x00 ],
    '9' => [ 0x7e, 0x00 ],
    ':' => [ 0x80, 0x00 ],
    '.' => [ 0x00, 0x02 ], # Lower left dot
    '*' => [ 0x00, 0x01 ], # Upper left dot
    '^' => [ 0x00, 0x04 ], # Upper right dot
  }

  def initialize(dev_no = 1, i2c_addr = 0x70)
    @i2c = I2C::Dev.create("/dev/i2c-#{dev_no}")
    @i2c_addr = i2c_addr
    display_on
  end

  def display_on
    i2c.write(i2c_addr, 0x21)
    display_brightness(8)
    i2c.write(i2c_addr, 0x81)
  end

  def display_off
    i2c.write(i2c_addr, 0x20)
  end

  def display_brightness(level)
    i2c.write(i2c_addr, 0xe0 | (level & 0x0f))
  end

  def dots(flags = {})
    low, high = 0, 0
    low |= 0x80 if flags[:colon]
    high |= 0x02 if flags[:lower_left]
    high |= 0x01 if flags[:upper_left]
    high |= 0x04 if flags[:upper_right]
    i2c.write(i2c_addr, 0, low, high)
  end

  def write_digits(s)
    if s.length <= 4
      i2c.write(i2c_addr, 2, *(s.chars.map{|c| SEVEN_SEGMENT_MAP[c] }.flatten))
    end
  end

  def start
    running = true
    count = 0
    colon = false
    Signal.trap("INT") do running = false end
    while(running) do
      write_digits(Time.now.localtime.strftime("%H%M"))
      sleep 0.25
      count += 1
      if count >= 4
        count = 0
        dots(colon: (colon = !colon))
      end
    end
    display_off
  end

end

ClockRadio.new.start
