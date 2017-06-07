class RHub < Controller
    defpacket_in datapath_id, message
        send_flow_mod_add(
            datapath_id,
            :match => ExactMatch.from( message ), 
            :actions => ActionOutput.new( OFPP_FLOOD ) 
        )
        send_packet_out( 
            datapath_id, 
            :packet_in => message, 
            :actions => ActionOutput.new( OFPP_FLOOD ) 
        ) 
    end 
end