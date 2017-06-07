


INFINITY_LINK_COST = 999999999


# methods for lldp frame
module Lldp_methods
  def lldp? message
    if message.macda.to_s == "01:80:c2:00:00:0e"
      return true
    else
      nil
    end
  end
  
  def to  message    
    return message.macsa.to_s.delete(":").to_i(16)
  end

  def from message 
    return message.datapath_id
  end

  def cost message
    # We will obtain a true link cost from the LLDP frame in the futur
    # We assume that link consts of the inbound and outbound are same, now

    # instead of real link cost
    cost = 10 
    
    return cost
  end
  
  def port message
    # in true, We should obtain port number form the payload of the LLDP frame
    # but We can't now, because We don't implement TLV of LLDP frame
    # so We use "message.in_port" instead of the port number in a LLDP frame
    return message.in_port
  end
end

class Lldp < Trema::LLDP
  include Lldp_methods

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
  def initialize c = INFINITY_LINK_COST, p = nil
    @port = p
    @cost = c
  end

  def cost c
    @cost = c
  end
  
  def link_cost
    return @cost
  end
  
  def port p
    @port = p
  end

  def port_num
    return @port
  end
end

class Topology
  include Lldp_methods
  
  def initialize 
    @switches = []
    @links = Hash.new { |hash,key| hash[key] = Hash.new {} }
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
    
    @switches -= [ datapath_id ]
  end

  def update message
    from_dpid = self.from message
    to_dpid = self.to message
    cost = self.cost message
    port = self.port message

    tmp = from_dpid.to_s(16)
    tmp2 = to_dpid.to_s(16)
    #puts "link exits #{tmp} to #{tmp2}, port #{port}, cost #{cost}"

    link = @links[from_dpid][to_dpid]
    #p link
    link.cost cost
    link.port port
  end

  def show_switches
    puts "All switches =  #{@switches.sort.join( ", " )}"
    
    @links.each do | dpid, tmp |
      @links[dpid].each do | dpid2, cost |
        #printf "%d ", @links[dpid][dpid2]
        tmp = dpid.to_s(16)
        tmp2 = dpid2.to_s(16)
        puts "link #{tmp} -> #{tmp2}"
        p @links[dpid][dpid2]
        puts ""
      end
      puts ""
    end
  end

  def switches
    return @switches
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
      p d 
      p y
      p b
      if tmp = min(d, y)
        now = tmp
        y -= [now]
        puts "now = #{now}"
      else
        break
      end
      
      printf "\n\n"


      y.each do | dpid |
        #p "#{d[dpid]} > #{d[now]} + #{@links[now][dpid].link_cost}"
        if d[dpid] > d[now] + @links[now][dpid].link_cost
          d[dpid] = d[now] + @links[now][dpid].link_cost
          b[dpid] = now
        end
      end

      sleep 2
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

end  

