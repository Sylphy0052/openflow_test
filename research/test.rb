class Test < Controller

    def start
        puts "trema clone start."
    end

    def switch_ready datapath_id
        puts "switch connect #{datapath_id.to_hex}"
        send_flow_mod_add(
          switchid,
          match:Match.new( dl_type: 0x0806 ),
          actions: SendOutPort.new( OFPP_FLOOD )
        )
    end

    # 宛先が192.10.1.10なら負荷分散処理
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
