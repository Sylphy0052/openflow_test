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
  self.table_name = 'Clones'
end

class Test < Controller

  periodic_timer_event :check_miclone, 7

  def start
    puts "trema test start"
    @dpid=[]
    @RootSwitch = 1
    @setdpid=[]
    @loadbarance = 2
    @targetip
    @srcip = "192.168.1.100"
    @dstip = "10.5.10.5"
    @setflag = 0 # 1 = migration / 2 = clone
  end

  def switch_ready datapath_id
    puts "switch ready  #{datapath_id.to_hex}"
    send_flow_mod_add( #ARP = FLOOD
                      datapath_id,
                      :match => Match.new( :dl_type => 0x0806 ),
                      :actions => SendOutPort.new( OFPP_FLOOD )
                      )
    @dpid.push(datapath_id)

    send_flow_mod_add(
                      datapath_id,
                      :match => Match.new( :dl_type => 0x0800 ,:nw_dst => "192.168.1.0/24"  ),
                      :actions => ActionOutput.new( :port => 1 )
                      )
    send_flow_mod_add(
                      datapath_id,
                      :match => Match.new( :dl_type => 0x0800 ,:nw_dst => "10.1.10.0/24"  ),
                      :actions => ActionOutput.new( :port => 2 )
                      )
    flow_mod_clone @srcip ,@dstip
  end

  def check_miclone
    result = Migration.first
    if !result.null?
      flow_mod_migration result.source_ip result.destination_ip

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



  def packet_in datapath_id, packet_in

    macsa = packet_in.macsa#source_mac_address
    macda = packet_in.macda#destination_mac_address
    ipsa = packet_in.ipv4_saddr#ipv4_source_address
    ipda = packet_in.ipv4_daddr#ipv4_destination_address


    if !ipsa.nil? && "0.0.0.0" != ipsa.to_s then
      puts "----------------------"
      puts "macsa : #{macsa}"
      puts "macda : #{macda}"
      puts "ipsa : #{ipsa.to_s}"
      puts "ipda : #{ipda.to_s}"
      puts "----------------------"

    end
  end

end
