class Test < Controller

    def start
        puts "trema clone start."
    end

    def switch_ready datapath_id
        puts "switch connect #{datapath_id.to_hex}"
        send_flow_mod_add(
          datapath_id,
          match:Match.new( dl_type: 0x0806 ),
          actions: SendOutPort.new( OFPP_FLOOD )
        )
        send_flow_mod_add(
          datapath_id,
          match: Match.new( dl_type: 0x0800,
                               nw_src: "192.168.3.2" ),
          actions: SendOutPort.new( 1 ),
          priority: 0xfff2
        )
        send_flow_mod_add(
          datapath_id,
          match: Match.new( dl_type: 0x0800,
                               nw_src: "192.10.1.10"),
          actions: SendOutPort.new( 3 ),
          priority: 0xfff2
        )
        send_flow_mod_add(
          datapath_id,
          match: Match.new( dl_type: 0x0800,
                               nw_src: "192.20.1.10"),
          actions: SendOutPort.new( 4 ),
          priority: 0xfff2
        )
    end

    def packet_in datapath_id, packet_in

        macsa = packet_in.macsa#source_mac_address
        macda = packet_in.macda#destination_mac_address
        ipsa = packet_in.ipv4_saddr#ipv4_source_address
        ipda = packet_in.ipv4_daddr#ipv4_destination_address

        if srcip == "192.10.1.10"
            puts "From 192.10.1.10"
        end

        if dstip == "192.10.1.10"
            puts "To 192.10.1.10"
        end

        if srcip == "192.20.1.10"
            puts "From 192.20.1.10"
        end

        if dstip == "192.20.1.10"
            puts "To 192.20.1.10"
        end

        if srcip == "192.168.3.2"
            puts "From 192.168.3.2"
        end

        if dstip == "192.168.3.2"
            puts "To 192.168.3.2"
        end

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
