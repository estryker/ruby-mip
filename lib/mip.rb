require 'ble'
require 'utils'

class MiP
  include Utils
  
  def initialize(uuid, port = 'hci0')
    @mip = BLE::Device.new('hci0',uuid)
    @mip.connect
    @mip_writer = @mip[0xFFE0, 0xFFE4]
    @mip_reader = @mip[0xFFE5, 0xFFE9]
  end

  def flash_chest(color, on_duration = 5, off_duration = 5)
    send_command(0x81, color_to_bytes(color), on_duration & 0xFF, off_duration & 0xFF)
  end

  # initial test for getting a response
  def get_status
    response = send_command(0x79)
    puts response[0].to_s(16) + response[1].to_s(16)
  end
  private

  # synchronous command sending
  def send_command(*args)
    # flatten the args, make sure each byte is between 0-0xFF, and send it.
    @mip_writer.write(args.flatten.map {|b| b & 0xFF}.pack(""))
    
    # return any response in packed byte format
    pack_response(@mip_reader.read)
  end

  def pack_response(response)
    # convert from ascii hex to an array of bytes. To be interpreted by the sending function
    # I'm not sure I'm reading the docs right. to be tested ...
    response.unpack("C*").pack("H*")
  end
  
end
