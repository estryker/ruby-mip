require 'ble'
require 'open3'
require 'io/wait'
require 'io/console'
require 'logger'
require '../lib/utils'

module BLE
  module Service
    add '0000ffe0-0000-1000-8000-00805f9b34fb',
        name: 'MiP Receive Data Service',
        nick: :mip_receive_data
    add '0000ffe5-0000-1000-8000-00805f9b34fb',
        name: 'MiP Send Data Service',
        nick: :mip_send_data
  end
  class Characteristic
    add '0000ffe4-0000-1000-8000-00805f9b34fb',
        name: 'MiP Receive Data Notify Characteristic',
        nick: :mip_receive_notify
    add '0000ffe9-0000-1000-8000-00805f9b34fb',
        name: 'MiP Send Data Write Characteristic',
        nick: :mip_send_write
  end
end


class MiP
  include Utils
  Sounds = %w{bang tone burping drinking eating farting out_of_breath boxing_punch_1 boxing_punch_2 boxing_punch_3 tracking_1 mip_1 mip_2 mip_3 
              app awww big_shot bleh boom bye converse_1 converse_2 drop dunno fall_over_1 fall_over_2 fight game gloat go gogogo grunt_1 
              grunt_2 grunt_3 got_it hi_confident hi_unsure hi_scared huh humming_1 humming_2 hurt huuurgh in_love it joke k loop_1 loop_2 
              low_battery mippee more muah_ha music obstacle oh_oh oh_yeah oopsie ouch_1 ouch_2 play push run shake sigh singing sneeze 
              snore stack swipe_1 swipe_2 tricks triiick trumpet waaaa wakey wheee whistling whoah woo yeah yeeesss yo yummy mood mood_angry 
              mood_anxious mood_boring mood_cranky mood_energetic mood_excited mood_giddy mood_grumpy mood_happy mood_idea mood_impatient 
              mood_nice mood_sad mood_short mood_sleepy mood_tired boost cage guns zings shortmute tracking2}
  # Add some MiP specific Services and Characteristics

  class << self

    # start the connection in block mode
    def start mac,interface: 'hci0', &blk
      mip = MiP.new(mac_address: mac, interface: interface)
      if block_given?
        begin
          mip.instance_eval(&blk)
        ensure
          mip.disconnect!
        end
      end
    end
  end

  def debug=(is_on)
    if is_on
      @logger.level = Logger::DEBUG 
    else
      @logger.level = Logger::WARN
    end
  end

  def initialize(mac_address:, interface: 'hci0')
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG
    
    @mac = mac_address
    @curr_speed = 15

    @adapter = BLE::Adapter.new(interface)
    puts "Info: #{@adapter.iface} #{@adapter.address} #{@adapter.name}"
    
    # Run discovery
    @adapter.start_discovery
    # sleeping less than 4 seconds seems to result in not finding all the services
    # TODO: is there a way to detect when discovery is actually done?
    sleep(4)
    @adapter.stop_discovery
    
    # Get device and connect to it
    @device = @adapter[mac_address]
    @connected = false
    @callbacks = Hash.new {|h,k| h[k] = []}
    @keyboard_commands = {}
    @command_help = []

    connect!
  end

  # set the new speed, up to 30
  def set_speed(new_speed:)
    if new_speed > 30
      new_speed = 30
    elsif new_speed < 0
      new_speed = 0
    end
    @curr_speed = new_speed 
  end

  # connect to MiP
  def connect_gatt!
    # until we can get ruby ble working, we are going to use the gatttool and
    # popen3 to send it commands
    # stdin, stdout, stderr, wait_thr = Open3.popen3("gatttool -b ")
    @mip_writer, @mip_reader, @mip_error, @gatt_pid = Open3.popen3("gatttool -b #{@mac} -I ")
    message = send_text_command "connect"
    if message.include?("Connection successful") # message.empty?
      @connected = true
    else
      raise "Couldn't connect to MiP: #{message}"
    end
  end

  def connect!  
    @device.connect
    @connected = true
    @device.subscribe(:mip_receive_data,:mip_receive_notify) do | response |
      # responses come back in ASCII Hex, upper case. No need to convert unless necessary
      @logger.debug "response: " + response.inspect
      code = response[0..1]
      message = response[2..-1]
      @callbacks[code].each {|c| c.call(message)}
    end
  end

  def on_gesture(direction: 'all', &blk)
     case direction
     when 'left','all'
      @callbacks["0A"] << response_proc("0A",&blk)
     when 'right','all'
      @callbacks["0A"] << response_proc("0B",&blk)
     when 'center_sweep_left','all'
      @callbacks["0A"] << response_proc("0C",&blk)
     when 'center_sweep_right','all'
      @callbacks["0A"] << response_proc("0D",&blk)
     when 'center_hold','all'
      @callbacks["0A"] << response_proc("0E",&blk)
     when 'forward','all'
      @callbacks["0A"] << response_proc("0F",&blk)
     when 'back','all'
      @callbacks["0A"] << response_proc("10",&blk)
     end
  end

  def on_status_check(&blk)
     @callbacks["79"] << response_proc(&blk)
  end

  # response procs will come in two flavors. 1 - if the code matches, call the block. 2. call the block with the message
  # TODO: make 2 response_proc methods to match the two flavors?
  def response_proc(code=nil,&blk)
     Proc.new do | message |
        if code.nil? or code.empty? or code == message
          @logger.debug "Calling proc. code: #{code} message: #{message}"
          blk.call(message)
        end
     end
  end

  # return a true/false if MiP is connected
  def connected?
    @connected
  end

  def disconnect!
    @device.disconnect
    @connected = false
  end

  # disconnect from MiP
  def disconnect_gatt!
    message = send_text_command "disconnect"
    
    if message.include? "disconnect"
      @connected = false
    else
      raise "Couldn't disconnect from MiP: #{message}"
    end

    @mip_writer.close
    @mip_reader.close
    @mip_error.close
    puts "closed"
  end

  # flash MiP's chest LED light
  def flash_chest(color: "red", on_duration: 5, off_duration: 5)
    send_command(0x89, color_to_bytes(color), on_duration & 0xFF, off_duration & 0xFF)
  end

  def set_chest_led(color: "green")
    send_command(0x84, color_to_bytes(color))
  end
  # initial test for getting a response
  def get_status
    send_command(0x79)
  end

  def gesture_mode_on! 
    send_command(0x0C,0x02)
  end

  def radar_mode_on!
    send_command(0x0C,0x04)
  end

  def gestures_and_radar_off!
    send_command(0x0C,0)
  end

  # move forward by duration or distance 
  def drive(duration: nil, distance: nil,backward: false,angle: 0)
    direction = backward ? 1 : 0
    if duration.nil? and not distance.nil?
      turn_dir = angle > 0 ? 0x0 : 0x1
      turn_angle = angle % 360
      turn_angle_high = turn_angle >> 8
      turn_angle_low = turn_angle & 0xFF
      send_command 0x70, direction, distance & 0xFF, turn_dir, turn_angle_high, turn_angle_low
      sleep(distance / 64.0)
    elsif not duration.nil? and distance.nil?
      send_command ((0x71 + direction) & 0xFF), @curr_speed, duration
      sleep(duration / 100)
    else
      raise "must specify exactly one of either duration or distance"
    end
  end


  # keep going until stop command if duration_seconds == 0
  # NOTE: this doesn't seem to work. Was going to use it for a keyboard mode, but will have to 
  #       use another method. 
  def continuous_drive(duration_seconds: 0, spin: 0, left_spin: false,backwards: false, crazy: false)
    speed = @curr_speed + 1
    spin += 0x41
    @logger.debug "A curr speed: #{@curr_speed} speed: #{speed}"
    speed += 0x20 if backwards # range for backwards is 0x21->
    spin += 0x20 if left_spin
    @logger.debug "B curr speed: #{@curr_speed} speed: #{speed}"
    if crazy 
      speed += 0x80 
      spin += 0x80
    end
    @logger.debug "C curr speed: #{@curr_speed} speed: #{speed}"
    time_start = Time.now
    until (Time.now - time_start) > duration_seconds
      send_command 0x78, speed & 0xFF ,spin & 0xFF
      sleep 0.01
    end
  end

  # turn right by given number of degrees
  def turnright(degrees: 90)
    send_command 0x74, ((degrees %360) / 5) & 0xFF, 10
    sleep 0.5
  end

  # turn left by given number of degrees
  def turnleft(degrees: 90)
    send_command 0x73, ((degrees %360) / 5) & 0xFF, 10
    sleep 0.5
  end

  # spin to the right by 360 degrees the specified number of times
  def spinright(num_times: 1)
    num_times.times do 
      send_command 0x74, 0x72,0x24
      sleep 1
    end
  end

  # spin to the left by 360 degrees the specified number of times
  def spinleft(num_times: 1)
    num_times.times do 
      send_command 0x73, 0x72,0x24
      sleep 1
    end
  end

  # stop moving forward
  def stop
    send_command 0x77
  end

  # play one of the sounds that MiP knows, from 1-106.
  # Or give it a sound name from the Sound Array
  def play_sound(sound: 0, duration: 1)
    @logger.debug "Playing sound: #{sound}"
    sound_number = 0
    case sound
    when String
      sound_number = Sounds.index(sound) || 0
    when Fixnum
      sound_number = sound
    end
    @logger.debug "sound number: #{sound_number}"
    send_command 0x6, sound_number % 106, duration & 0xFF
    sleep(duration)
  end

  def fall_back
    send_command 0x8, 0x0
  end
  
  def fall_forward
    send_command 0x8, 0x1
  end

  # this doesn't seem to work. It seems to be more of a physics thing
  def getup
    send_command 0x23, 0x2
  end

  def on_keyboard_command(command_char, help_str, &blk)
    @keyboard_commands[command_char] = blk
    @command_help << "#{command_char}\t#{help_str}\n"
  end

  def keyboard_mode
    begin
    #STDIN.echo = false
    #STDIN.raw!
    old_stty_state = `stty -g`
    stty_string = "stty raw"
    stty_string += " -echo" unless @logger.level == Logger::DEBUG
    system stty_string 
    prev_key = ""
    while true
      c = STDIN.getc.chr
      # special characters like arrow keys. could be 3 or 2 bytes
      if c == "\e" then
       c << STDIN.read_nonblock(3) rescue nil
       c << STDIN.read_nonblock(2) rescue nil
      end
      curr_key = c
      case c
      when "\e[A"
        continuous_drive duration_seconds: 0.1
      when "\e[B"
        continuous_drive duration_seconds: 0.1,backwards: true
      when "\e[C"
        turnright degrees: 30
        #continuous_drive duration_seconds: 0.1 unless @curr_speed == 0
      when "\e[D"
        turnleft degrees: 30
        #continuous_drive duration_seconds: 0.1 unless @curr_speed == 0
      when "a"
        #TODO: test to see what the max speed is. for now, keep it in one byte
        if @curr_speed < 30
          @curr_speed += 5
        else
          @curr_speed = 30
        end
      when "z"
        if @curr_speed > 5
          @curr_speed -= 5
        else
          @curr_speed = 0
        end
      when "h"
        puts @command_help
      when "/"
        # do I need to get us out of raw mode??
        STDIN.echo = true
        print "/"
        STDIN.cooked!
        command,arg = gets.strip.split " "
        if @keyboard_commands.has_key? command
          @keyboard_commands[command].call(arg)
        else
          puts "Unknown command"
          puts @command_help
        end
        STDIN.echo = false unless @logger.level == Logger::DEBUG 
        STDIN.raw!
      when "\u0003"
        puts "Quiting ..."
        break
     
      end
      prev_key = curr_key
      end
    ensure
      system "stty #{old_stty_state}"
      #STDIN.echo = true
      #STDIN.cooked!
    end
  end

  # used in command input
  def read_char
    STDIN.echo = false
    STDIN.raw!

    input = STDIN.getc.chr
    if input == "\e" then
     input << STDIN.read_nonblock(3) rescue nil
     input << STDIN.read_nonblock(2) rescue nil
    end
  ensure
   STDIN.echo = true
   STDIN.cooked!

    return input
  end

  # :nodoc: 
  def method_missing(method_name, *args, **named_args,&block)
    # puts method_name
    if mobj = method_name.to_s.match(/^play_([a-z]{1,100})_sound$/)
      sound_name = mobj[1]
      if Sounds.index(sound_name)
        play_sound(sound: sound_name, duration: named_args[:duration] )
      else
        super
      end
    else
      super
    end
  end

  # :nodoc: 
  def respond_to_missing?(method_name, *args)
    if mobj = method_name.to_s.match(/^play_([a-z]{1,100})_sound$/)
      sound_name = mobj[1]
      if Sounds.index(sound_name)
        return true
      end
    end
    return false
  end
  
  :private
  
  # :nodoc: 
  def send_text_command command

    # this is a kludge. We need to pause until the command should have executed
    @mip_writer.puts(command)
    sleep(3)
    until @mip_reader.ready?
      sleep(1)
    end

    @mip_reader.read_nonblock(1000)
  end


  # for now lets not allow users to send commands directly.
  # Note that I would rather use Ruby BLE or dbus to send commands, but this abstraction *should*
  # make the change easy later
  # :nodoc:
  def send_command_old(*args)
    # flatten the args, make sure each byte is between 0-0xFF, and send it.
    command_str = "char-write-cmd 0x001b " + args.flatten.map {|b| sprintf("%02X", b & 0xFF)}.join
    # puts command_str
    @mip_writer.puts(command_str)
    
    # TODO: check to see if the reader has anything in the buffer, then read
    until @mip_reader.ready?
      sleep(1)
    end
    @response = @mip_reader.read_nonblock(1000)[command_str.length+1 .. -1]
                      
    # return any response in packed byte format
    # pack_response(@mip_reader.read)
  end

  def send_command(*args)
    # flatten the args, make sure each byte is between 0-0xFF, and send it.
    command_str = args.flatten.pack("C*")
    @logger.debug command_str.inspect
    @logger.debug args.flatten.map {|b| sprintf("%02X", b & 0xFF)}.join
    @device.write(:mip_send_data, :mip_send_write, command_str, raw: true, async: true)    
    # return any response in packed byte format
    # pack_response(@mip_reader.read)
  end

  # :nodoc:
  def pack_response(response)
    # convert from ascii hex to an array of bytes. To be interpreted by the sending function
    # I'm not sure I'm reading the docs right. to be tested ...
    response.unpack("C*").pack("H*")
  end

end

__END__
@mip = BLE::Device.new('hci0',uuid)
    num_tries = 0
    begin
      @mip.connect
    rescue Exception
      sleep 1
      num_tries += 1
      retry unless num_tries > 10
    end
    unless @mip.is_connected?
      raise "Couldn't connect to MiP"
    end


    
https://github.com/WowWeeLabs/MiP-BLE-Protocol

Send Data Service: 0xFFE5

 Send Data WRITE Characteristic: 0xFFE9


Discovery primary services
0000ffe5-0000-1000-8000-00805f9b34fb  -> should be the 
ethan@ethan-VirtualBox:~/ruby-mip/lib$ sudo gatttool -b 1C:37:8D:FB:20:87 --primary
attr handle = 0x0001, end grp handle = 0x0007 uuid: 00001800-0000-1000-8000-00805f9b34fb
attr handle = 0x0008, end grp handle = 0x0008 uuid: 00001801-0000-1000-8000-00805f9b34fb
attr handle = 0x0009, end grp handle = 0x000c uuid: 0000180f-0000-1000-8000-00805f9b34fb
attr handle = 0x000d, end grp handle = 0x0013 uuid: 0000180a-0000-1000-8000-00805f9b34fb
attr handle = 0x0014, end grp handle = 0x0018 uuid: 0000ffe0-0000-1000-8000-00805f9b34fb
attr handle = 0x0019, end grp handle = 0x001c uuid: 0000ffe5-0000-1000-8000-00805f9b34fb
attr handle = 0x001d, end grp handle = 0x0022 uuid: 0000ffa0-0000-1000-8000-00805f9b34fb
attr handle = 0x0023, end grp handle = 0x002f uuid: 0000ff90-0000-1000-8000-00805f9b34fb
attr handle = 0x0030, end grp handle = 0x0047 uuid: 0000ff00-0000-1000-8000-00805f9b34fb
attr handle = 0x0048, end grp handle = 0xffff uuid: 0000ff30-0000-1000-8000-00805f9b34fb


Then all the characteristics
ethan@ethan-VirtualBox:~/ruby-mip/lib$ sudo gatttool -b 1C:37:8D:FB:20:87 --characteristics
handle = 0x0002, char properties = 0x0a, char value handle = 0x0003, uuid = 00002a00-0000-1000-8000-00805f9b34fb
handle = 0x0004, char properties = 0x02, char value handle = 0x0005, uuid = 00002a01-0000-1000-8000-00805f9b34fb
handle = 0x0006, char properties = 0x02, char value handle = 0x0007, uuid = 00002a04-0000-1000-8000-00805f9b34fb
handle = 0x000a, char properties = 0x12, char value handle = 0x000b, uuid = 00002a19-0000-1000-8000-00805f9b34fb
handle = 0x000e, char properties = 0x02, char value handle = 0x000f, uuid = 00002a23-0000-1000-8000-00805f9b34fb
handle = 0x0010, char properties = 0x02, char value handle = 0x0011, uuid = 00002a26-0000-1000-8000-00805f9b34fb
handle = 0x0012, char properties = 0x02, char value handle = 0x0013, uuid = 00002a29-0000-1000-8000-00805f9b34fb
handle = 0x0015, char properties = 0x10, char value handle = 0x0016, uuid = 0000ffe4-0000-1000-8000-00805f9b34fb
handle = 0x001a, char properties = 0x0c, char value handle = 0x001b, uuid = 0000ffe9-0000-1000-8000-00805f9b34fb
handle = 0x001e, char properties = 0x12, char value handle = 0x001f, uuid = 0000ffa1-0000-1000-8000-00805f9b34fb
handle = 0x0021, char properties = 0x0a, char value handle = 0x0022, uuid = 0000ffa2-0000-1000-8000-00805f9b34fb
handle = 0x0024, char properties = 0x0a, char value handle = 0x0025, uuid = 0000ff91-0000-1000-8000-00805f9b34fb
handle = 0x0026, char properties = 0x0a, char value handle = 0x0027, uuid = 0000ff92-0000-1000-8000-00805f9b34fb
handle = 0x0028, char properties = 0x08, char value handle = 0x0029, uuid = 0000ff94-0000-1000-8000-00805f9b34fb
handle = 0x002a, char properties = 0x0a, char value handle = 0x002b, uuid = 0000ff95-0000-1000-8000-00805f9b34fb
handle = 0x002c, char properties = 0x0a, char value handle = 0x002d, uuid = 0000ff97-0000-1000-8000-00805f9b34fb
handle = 0x002e, char properties = 0x0a, char value handle = 0x002f, uuid = 0000ff98-0000-1000-8000-00805f9b34fb
handle = 0x0031, char properties = 0x02, char value handle = 0x0032, uuid = 0000ff01-0000-1000-8000-00805f9b34fb
handle = 0x0033, char properties = 0x08, char value handle = 0x0034, uuid = 0000ff02-0000-1000-8000-00805f9b34fb
handle = 0x0035, char properties = 0x08, char value handle = 0x0036, uuid = 0000ff03-0000-1000-8000-00805f9b34fb
handle = 0x0037, char properties = 0x08, char value handle = 0x0038, uuid = 0000ff04-0000-1000-8000-00805f9b34fb
handle = 0x0039, char properties = 0x10, char value handle = 0x003a, uuid = 0000ff05-0000-1000-8000-00805f9b34fb
handle = 0x003c, char properties = 0x02, char value handle = 0x003d, uuid = 0000ff06-0000-1000-8000-00805f9b34fb
handle = 0x003e, char properties = 0x08, char value handle = 0x003f, uuid = 0000ff07-0000-1000-8000-00805f9b34fb
handle = 0x0040, char properties = 0x10, char value handle = 0x0041, uuid = 0000ff08-0000-1000-8000-00805f9b34fb
handle = 0x0043, char properties = 0x0c, char value handle = 0x0044, uuid = 0000ff09-0000-1000-8000-00805f9b34fb
handle = 0x0045, char properties = 0x10, char value handle = 0x0046, uuid = 0000ff0a-0000-1000-8000-00805f9b34fb
handle = 0x0049, char properties = 0x08, char value handle = 0x004a, uuid = 0000ff31-0000-1000-8000-00805f9b34fb

