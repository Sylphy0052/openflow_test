require 'arp-table'
require 'interface'
require 'routing-table'
require 'ipaddr'
require 'active_record'

ActiveRecord::Base.establish_connection(
  "adapter" => "sqlite3",
  "database" =>"./change.db"
)

class Migration < ActiveRecord::Base
  self.table_name = 'migrations'
end
class Clone < ActiveRecord::Base
  self.table_name = 'clones'
end
class Load_balance < ActiveRecord::Base
  self.table_name = "load_balances"
end

class SimpleRouter < Controller

  periodic_timer_event :check_miclone, 10


  def start
    puts "test Start"
    load 'simple_router.conf'
    @interfaces = Interfaces.new($interface)
    @arp_table = ARPTable.new
    @routing_table = RoutingTable.new($route)
    @dpid=[]
    @RootSwitch = 1
    @setdpid=[]
    @loadbarance = 2
    @targetip
    @srcip = "192.168.1.100"
    @dstip = "10.5.10.5"
    @setflag = 0 # 1 = migration / 2 = clone  
  end


  def switch_ready dpid
    puts "DPID : #{dpid.to_hex} is ready"
    if !dpid == @RootSwitch
      send_flow_mod_add( datapath_id, :actions => SendOutPort.new( OFPP_FLOOD ) )
    end
  end


  def packet_in(dpid, message)

    puts "packet capture"
    
    if dpid = @RootSwitch
      return if not to_me?(message)
      
      if message.arp_request?
        handle_arp_request dpid, message
      elsif message.arp_reply?
        handle_arp_reply message
      elsif message.ipv4?
        handle_ipv4 dpid, message
      else
        # noop.
      end
    end
  end



  def check_miclone
    result = Migration.first
    if !result.nil?
      flow_mod_migration result.source_ip result.destination_ip
      Migration.where(:source_ip => result.source_ip, :destination_ip => result.destination_ip).delete_all
    end
    result = Clone.first
    if !result.nil?
      flow_mod_migration result.source_ip result.destination_ip
      Clone.where(:source_ip => result.source_ip, :destination_ip => result.destination_ip).delete_all
      Load_balance.create(:source_ip => result.source_ip,
                          :source_mac => @arp_table.lookup(result.source_ip),
                          :balance_ip => result.destination_ip,
                          :balance_mac => @arp_table.lookup(result.destination_ip))
    end
  end



  def flow_mod_clone srcip,dstip
    @flag = 2
    @srcip = srcip
    @dstip = dstip
    send_message(@RootSwitch, FlowStatsRequest.new(:match => Match.new()))
  end

  def flow_mod_migration srcip, dstip
    @flag = 1
    @srcip = srcip
    @dstip = dstip
    send_message(@RootSwitch, FlowStatsRequest.new(:match => Match.new()))
  end

  def stats_reply dpid, message
    if message.type == Trema::StatsReply::OFPST_FLOW
      message.stats.each do |each|
        if !each.match.nw_dst.to_s.eql?("0.0.0.0")
          split = each.match.to_s.split("nw_dst = ")
          nw_dst = split[1].split(",",2)
          range = IPAddr.new(nw_dst[0])
 #-------------------Migration ------------------------   
          if @flag == 1
            if range.include?(IPAddr.new(@srcip))
              if !range.include?(IPAddr.new(@dstip))
                puts "migration hit"
                send_flow_mod_delete(
                                     dpid,
                                     :match => each.match
                                     )
                puts "hit delete: priority -1 add"
                send_flow_mod_add(
                                  dpid,
                                  :match => each.match,
                                  :actions => each.actions,
                                  :priority => each.priority - 1
                                  )
                #reply
                actionback =
                  [
                   SetIpSrcAddr.new( @srcip ),
                   SendOutPort.new( 3 )
                  ]
                
                #back packet from migration vm to cli
                send_flow_mod_add(
                                  @RootSwitch,
                                  :match => Match.new(:dl_type => 0x0800 ,
                                                      :nw_src => @dstip),
                                  :actions => actionback
                                  )
              end
            end
            
            if range.include?(IPAddr.new(@dstip))
              if !range.include?(IPAddr.new(@srcip))
                each.actions.each do |action|
                  if action.to_s.include?("SendOutPort")
                    puts "PORT-------------#{action.port_number}"
                   #send 
                    actionsend =
                      [
                       SetIpDstAddr.new( @dstip ),
                       SendOutPort.new( action.port_number )
                      ]
                    send_flow_mod_add(
                                      @RootSwitch,
                                      :match => Match.new(:dl_type => 0x0800,
                                                          :nw_dst => @srcip ),
                                      :actions => actionsend
                                      )
                  end
                end
              end
            end
 #------------------------Clone------------------------- 
          elsif @flag == 2 # clone
            if range.include?(IPAddr.new(@srcip))
              puts "clone hit"
              send_flow_mod_delete(
                                   dpid,
                                   :match => each.match
                                   )
              puts "hit delete: priority -1 add"
              send_flow_mod_add(
                                dpid,
                                :match => each.match,
                                :actions => each.actions,
                                :priority => each.priority - 1
                                )
              send_flow_mod_add(
                                dpid,
                                :match => Match.new(:nw_dst => @srcip),
                                :actions => SendOutPort.new( OFPP_CONTROLLER )
                                )
            end
          end
        end
      end
    end
  end
  





  private

  def to_me?(message)
    return true if message.macda.broadcast?

    interface = @interfaces.find_by_port(message.in_port)
    if interface and interface.has?(message.macda)
      return true
    end
  end

  def handle_arp_request(dpid, message)
    port = message.in_port
    daddr = message.arp_tpa
    interface = @interfaces.find_by_port_and_ipaddr(port, daddr)
    if interface
      arp_reply = create_arp_reply_from(message, interface.hwaddr)
      packet_out dpid, arp_reply, SendOutPort.new(interface.port)
    end
  end

  def handle_arp_reply(message)
    @arp_table.update message.in_port, message.arp_spa, message.arp_sha
  end

  def handle_ipv4(dpid, message)
    if should_forward?(message)
      forward dpid, message
    elsif message.icmpv4_echo_request?
      handle_icmpv4_echo_request dpid, message
    else
      # noop.
    end
  end

  def should_forward?(message)
    not @interfaces.find_by_ipaddr(message.ipv4_daddr)
  end

  def handle_icmpv4_echo_request(dpid, message)
    interface = @interfaces.find_by_port(message.in_port)
    saddr = message.ipv4_saddr
    arp_entry = @arp_table.lookup(saddr)
    if arp_entry
      icmpv4_reply = create_icmpv4_reply(arp_entry, interface, message)
      packet_out dpid, icmpv4_reply, SendOutPort.new(interface.port)
    else
      handle_unresolved_packet dpid, message, interface, saddr
    end
  end

  def forward(dpid, message)
    next_hop = resolve_next_hop(message.ipv4_daddr)

    interface = @interfaces.find_by_prefix(next_hop)
    if not interface or interface.port == message.in_port
      return
    end

    arp_entry = @arp_table.lookup(next_hop)
    if arp_entry
      macsa = interface.hwaddr
      macda = arp_entry.hwaddr
      action = create_action_from(macsa, macda, interface.port)
      flow_mod dpid, message, action
      packet_out dpid, message.data, action
    else
      handle_unresolved_packet dpid, message, interface, next_hop
    end
  end

  def resolve_next_hop(daddr)
    interface = @interfaces.find_by_prefix(daddr.value)
    if interface
      daddr
    else
      @routing_table.lookup(daddr.value)
    end
  end

  def flow_mod(dpid, message, action)
    send_flow_mod_add(
      dpid,
      :match => ExactMatch.from(message),
      :actions => action
    )
  end

  def packet_out(dpid, packet, action)
    send_packet_out(
      dpid,
      :data => packet,
      :actions => action
    )
  end

  def handle_unresolved_packet(dpid, message, interface, ipaddr)
    arp_request = create_arp_request_from(interface, ipaddr)
    packet_out dpid, arp_request, SendOutPort.new(interface.port)
  end

  def create_action_from(macsa, macda, port)
    [
      SetEthSrcAddr.new(macsa),
      SetEthDstAddr.new(macda),
      SendOutPort.new(port)
    ]
  end

  def create_arp_request_from(interface, addr)
    Pio::Arp::Request.new(
      :source_mac => interface.hwaddr,
      :sender_protocol_address => interface.ipaddr,
      :target_protocol_address => addr
    ).to_binary
  end

  def create_arp_reply_from(message, replyaddr)
    Pio::Arp::Reply.new(
      :source_mac => replyaddr,
      :destination_mac => message.macsa,
      :sender_protocol_address => message.arp_tpa,
      :target_protocol_address => message.arp_spa
    ).to_binary
  end

  def create_icmpv4_reply(entry, interface, message)
    request = Pio::Icmp.read(message.data)
    Pio::Icmp::Reply.new(
      :destination_mac => entry.hwaddr,
      :source_mac => interface.hwaddr,
      :ip_source_address => message.ipv4_daddr,
      :ip_destination_address => message.ipv4_saddr,
      :icmp_identifier => request.icmp_identifier,
      :icmp_sequence_number => request.icmp_sequence_number,
      :echo_data => request.echo_data
    ).to_binary
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
