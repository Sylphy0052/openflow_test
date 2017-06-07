class NAT
  def initialize
    @table = { "192.168.100.2" => "192.168.100.3", "192.168.57.4" => "192.168.57.5", "192.168.0.1" => "192.168.0.100" }
    @mac = {}
  end
  
  def nat message, actions
    src = message.ipv4_saddr.to_s
    dst = message.ipv4_daddr.to_s
      
    if @table[src] 
      actions.unshift( Trema::ActionSetNwSrc.new( :nw_src => Trema::IP.new(@table[src]) ) )
      @mac[ @table[src] ] = message.macsa.to_s
    elsif @table.index dst
      actions.unshift( Trema::ActionSetNwDst.new( :nw_dst => Trema::IP.new(@table.index dst) ) )
    end
  end

  # Is there IP address in nat table?
  def has_ip? ip
    if @table.index ip.to_s
      return true
    else
      return nil
    end    
  end
  
  def has_mac_for? ip
    if @mac.has_key? ip.to_s
      return true
    else
      return nil
    end
  end
      
  def mac_for ip
    return @mac[ip.to_s]
  end  
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
