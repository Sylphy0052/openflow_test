# -*- coding: utf-8 -*-
class Migrate < Controller

# Migrate From PM1 to PM2

    def start
        if ARGV.size != 2 then
            puts("tream run migrate.rb from_ip to_ip")
            exit(1)
        end
        puts "trema migrate start."
        puts "clone from #{ARGV[0]} to #{ARGV[1]}"
        @from_ip = ARGV[0]
        @to_ip = ARGV[1]
        @flag = 0
        # @ipcache = []
        @vm_mac = "02:fd:01:de:ad:34"
        # @pm1_mac = "b8:27:eb:47:8e:ed"
        # @pm2_mac = "b8:27:eb:22:e2:9f"
        # @pm1_ip = "192.10.1.10"
        # @pm2_ip = "192.20.1.10"
        # @pm1_port = 2
        # @pm2_port = 3
        # @port = 1
    end

    def switch_ready datapath_id
        puts "switch connect #{datapath_id.to_hex}"

        send_flow_mod_add(
            datapath_id,
            :match => Match.new( :dl_type => 0x0806 ),
            :actions => SendOutPort.new( OFPP_FLOOD )
        )

        # 192.10.1.10から来たパケットを1番ポートに転送
        # send_flow_mod_add(
        #     datapath_id,
        #     :match => Match.new(
        #         :dl_type => 0x0800 ,
        #         :nw_src => @pm1_ip ),
        #     :actions => SendOutPort.new( @port )
        # )
        # 192.20.1.10から来たパケットの転送元を書き換えて1番ポートに転送
        # action1 =
        # [
        #     SetEthSrcAddr.new( @pm1_mac ),
        #     SetIpSrcAddr.new( @pm1_ip ),
        #     SendOutPort.new( @port )
        # ]
        # send_flow_mod_add(
        #     datapath_id,
        #     :match => Match.new(
        #         :dl_type => 0x0800 ,
        #         :nw_dst => @pm2_ip ),
        #     :actions => action1
        # )
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

        srcip = packet_in.ipv4_saddr.to_s
        dstip = packet_in.ipv4_daddr.to_s
        # マイグレーション前あてのパケットならマイグレーション後に変更
        if dstip == @pm1_ip
            puts ""
            puts "Send to Before Migrate PM From #{srcip} to #{dstip}"

            action1 = [
                SetEthDstAddr.new( @vm_mac ),
                SetIpDstAddr.new( @to_ip ),
                SendOutPort.new( OFPP_FLOOD )
            ]

            send_flow_mod_add(
                datapath_id,
                :match => Match.new(
                    :dl_type => 0x0800,
                    :nw_src => packet_in.ipv4_saddr
                ),
                :actions => action1
            )

            send_packet_out(
                datapath_id,
                :data => packet_in.data,
                :actions => SendOutPort.new( OFPP_FLOOD )
            )
        end

        if srcip == @pm2_ip
            puts ""
            puts "Send to Client From After Migrate PM From #{srcip} to #{dstip}"

            action2 = [
                SetEthSrcAddr.new( @vm_mac ),
                SetIpSrcAddr.new( @from_ip ),
                SendOutPort.new( OFPP_FLOOD )
            ]

            send_flow_mod_add(
                datapath_id,
                :match => Match.new(
                    :dl_type => 0x0800,
                    :nw_src => @to_ip
                ),
                :actions => action2
            )

            send_packet_out(
                datapath_id,
                :data => packet_in.data,
                :actions => SendOutPort.new( OFPP_FLOOD )
            )
        end
    end

    # フローエントリー削除
    def flow_removed datapath_id, message
        delip = message.match.nw_src.to_s
        puts ""
        puts "delete #{delip}"
    end
end
