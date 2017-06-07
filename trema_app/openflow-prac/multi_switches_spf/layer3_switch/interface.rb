

class L3_INTERFACE
  attr_reader :ipaddr
  attr_reader :macaddr
  
  # args
  # ip -> String
  # prefix -> integer
  # mac -> String
  def initialize ip, prefix, mac = $DEFAULT_GW_MAC
    @ipaddr = Trema::IP.new ip
    @network = Trema::IP.new ip, prefix
    @prefix = prefix
    @macaddr = Trema::Mac.new mac
  end

  # dst -> Trema::IP
  def reach? dst
    if (Trema::IP.new dst.to_s, @prefix) == @network
      true
    else
      nil
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:

