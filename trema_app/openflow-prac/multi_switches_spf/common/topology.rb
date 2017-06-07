


INFINITY_LINK_COST = 9999999999999999999999999

# add method for check LLDP frame
class Trema::PacketIn
  def lldp? 
    if self.macda.to_s == "01:80:c2:00:00:0e"
      true
    else
      nil
    end
  end
end


class Trema::LLDP
  def probe datapath_id
    mac_over_12chars = datapath_id.to_s(16).rjust(12, "0")
    length = mac_over_12chars.length
    src_mac = mac_over_12chars.slice(length - 12, 12)
  
    src_mac.insert 2, ":"
    src_mac.insert 5, ":"
    src_mac.insert 8, ":"
    src_mac.insert 11, ":"
    src_mac.insert 14, ":"
    #puts "in Ruby #{src_mac}"

    self.send_packet_out_lldp datapath_id, src_mac
  end
end



class LINK
  attr_accessor :port, :cost
  
  def initialize c = INFINITY_LINK_COST, p = nil
    @port = p
    @cost = c
  end
end

class Topology
  def initialize 
    @switches = []
    @links = Hash.new { |hash,key| hash[key] = Hash.new {} }
    @hosts = {}
    @show_times = 4
  end
  
  def update_hosts datapath_id, all_ports
    all_ports -= [65534] # what is 65534? # all_ports includes ports to switches and hosts

    @links[datapath_id].each do | dpid, link |
      all_ports -= [link.port]
    end

    #puts "ports for hosts on dpid = #{datapath_id} is"
    #p all_ports

    @hosts[datapath_id] = all_ports
  end
  
  def add_sw datapath_id
    @switches << datapath_id
    
    @switches.each do | dpid |
      @links[datapath_id][dpid] = LINK.new
      @links[dpid][datapath_id] = LINK.new
    end
    @links[datapath_id][datapath_id] = LINK.new
  end

  def del_sw datapath_id
    @switches.each do | dpid |
      @links[dpid].delete datapath_id
      @links[datapath_id].delete dpid
    end
    @switches -= [datapath_id]
    @hosts.delete datapath_id
  end

  def port_no_of from_dpid, to_dpid
    return @links[from_dpid][to_dpid].port
  end

  def update_topology message
    from_dpid = link_from message
    to_dpid = link_to message
    cost = link_cost message
    port = link_port message
    
    link = @links[from_dpid][to_dpid]
    return if not link
    
    link.cost = cost
    link.port = port
  end

  def show
    if @show_times > 0
      puts "All switches =  #{@switches.sort.join( ", " )}"
      puts "All links ="
      @links.each do | from_dpid, foo |
        @links[from_dpid].each do | to_dpid, link |
          tmp = from_dpid.to_s(16)
          tmp2 = to_dpid.to_s(16)
          tmp3 = link.port
          puts "link dpid = #{tmp}, port = #{tmp3} -> dpid = #{tmp2}" if tmp3
        end
      end
      puts "All hosts port is"
      p @hosts

      @show_times -= 1
    end
  end

  def switches
    return @switches
  end
  
  def hosts
    return @hosts
  end
  
  
  # calculate shortest path by djikstra algorithm
  # return array [start, hoge, ..., goal]
  # infinite loop in this method, when there is a 
  # switch that has no links any other switches
  def path start, goal
    # distance => d
    d = {}
    # before node => b
    b = {}
    # don't probe node yet => y
    y = []
    # now
    now = start

    @switches.each do | dpid |
      d[dpid] = INFINITY_LINK_COST
      b[dpid] = nil
      y << dpid
    end
    d[now] = 0 

    until y.empty?
      #p d 
      #p y
      #p b
      if tmp = min(d, y)
        now = tmp
        y -= [now]
        #puts "now = #{now}"
      else
        break
      end
      #printf "\n\n"
      

      y.each do | dpid |
        if d[dpid] > d[now] + @links[now][dpid].cost
          d[dpid] = d[now] + @links[now][dpid].cost
          b[dpid] = now
        end
      end
    end

    route = [goal]
    until route[0] == start
      route.unshift( b[ route[0] ] )
    end
    return route
  end
  

  
  #############################################################################
  private
  #############################################################################
  def min d, y
    min = INFINITY_LINK_COST
    index = nil
    
    y.each do | dpid | 
      if min > d[dpid]
        min = d[dpid]
        index = dpid
      end
    end
    
    return index
  end

  def link_to  message
    return message.lldp_src_datapath_id
    #return message.macsa.to_s.delete(":").to_i(16)
  end

  def link_from message 
    return message.datapath_id
  end

  def link_cost message
    # We will obtain a true link cost from the LLDP frame in the futur
    # We assume that link consts of the inbound and outbound are same, now
    # instead of real link cost
    cost = 10 
    return cost
  end
  
  def link_port message
    # in true, We should obtain port number form the payload of the LLDP frame
    # but We can't now, because We don't implement TLV of LLDP frame
    # so We use "message.in_port" instead of the port number in a LLDP frame
    return message.in_port
  end

end  

