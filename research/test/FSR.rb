
class FlowController < Trema::FlowStatsRequest

  def send_message_flowstatsrequest
    send_message(@dpid, FlowStatsRequest.new(:match => Match.new()))
  end

  def stats_reply dpid ,message
    puts "[FlowDumper::stats_reply]"
    
    puts "stats of dpid:#{dpid}"
    puts "* transaction id: #{message.transaction_id}"
    puts "* flags: #{message.type}"
    puts "* type: #{message.type}"
    
    if message.type == Trema::StatsReply::OFPST_FLOW
      message.stats.each do |each|
        puts "* stats:"
=begin                                                                                                                  puts "  * length: #{each.length}"                                                                               puts "  * table_id: #{each.table_id}"                                                                           puts "  * duration_sec: #{each.duration_sec}"                                                                   puts "  * duration_nsec: #{each.duration_nsec}"                                                                 puts "  * priority: #{each.priority}"                                                                           puts "  * idle_timeout: #{each.idle_timeout}"                                                                   puts "  * hard_timeout: #{each.hard_timeout}"                                                                   puts "  * cookie: #{each.cookie.to_hex}"                                                                        puts "  * packet_count: #{each.packet_count}"                                                                   puts "  * byte_count: #{each.byte_count}"                                                                       puts "  * actions:"                                                                         
=end
        puts each.match.nw_dst.to_s
        puts "  * match: #{each.match.nw_dst}"
        each.actions.each do |action|
          puts "    * #{action.to_s}"
        end
      end
    end
    #    puts message.stats
  
  end
end
