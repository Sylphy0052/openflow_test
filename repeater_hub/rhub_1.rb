class RHub < Controller

    def start
        puts "rhub start"
    end

    def switch_ready dpid
        puts "#{dpid.to_hex} is ready"
    end

    def packet_in datapath_id, message
        puts "datapath : #{datapath_id} message : #{message}"
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
