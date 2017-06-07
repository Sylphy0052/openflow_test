# -*- coding: utf-8 -*-
 require "counter"
 require "fdb"

 class TrafficMonitor < Controller
   periodic_timer_event :show_counter, 10

   def start
     @counter = Counter.new
     @fdb = FDB.new
   end

#   periodic_timer_event @counter.show_counter, 10

  def packet_in datapath_id, message
     macsa = message.macsa
     macda = message.macda

     @fdb.learn macsa, message.in_port
     @counter.add datapath_id, macsa, 1, message.total_len
     out_port = @fdb.lookup( macda )
     if out_port
       packet_out datapath_id, message, out_port
       flow_mod datapath_id, macsa, macda, out_port
     else
       flood datapath_id, message
     end
   end
   
   def flow_removed datapath_id, message
     @counter.add datapath_id, message.match.dl_src, message.packet_count, message.byte_count
   end
   
   private

   def show_counter
     @counter.show_counter
   end
=begin
   def show_counter
     puts Time.now
     #     @counter.dbeach_pair do | mac, counter |
     #       puts "#{ mac } #{ counter[ :packet_count ] } packets (#{ counter[ :byte_count ] } bytes)"
     #progress_bar(:byte_count)
     #     end
     puts "-------------------------------------------------------------"
     @counter.sweach_pair do | dpid, counter |
       puts "Switch Traffic #{ dpid }\t : \t#{ counter[ :packet_count ] } packets (#{ counter[ :byte_count ] } bytes)"
     end
     puts "-------------------------------------------------------------"
     @counter.counter_reset
   end
=end
   def flow_mod datapath_id, macsa, macda, out_port
     send_flow_mod_add(
                       datapath_id,
                       :hard_timeout => 10,
                       :match => Match.new( :dl_src => macsa, :dl_dst => macda ),
                       :actions => ActionOutput.new( out_port )
                       )
   end
   
   def packet_out datapath_id, message, out_port
     send_packet_out(
                     datapath_id,
                     :packet_in => message,
                     :actions => ActionOutput.new( out_port )
                     )
   end
    
   def flood datapath_id, message
     packet_out datapath_id, message, OFPP_FLOOD
   end
 end
