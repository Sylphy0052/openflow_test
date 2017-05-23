# host:192.168.3.7 / a4:5e:60:e4:3a:b9
# PM1:192.10.1.10
# PM2:192.10.1.20
#
# 1番ポート
# 2番ポート
# 3番ポート

class LoadBalancer < Controller

    HOST_IP = "192.168.3.7"
    PM1_IP = "192.10.1.10"
    PM2_IP = "192.10.1.20"
    HOST_MAC = "a4:5e:60:e4:3a:b9"
    PM1_MAC = "b8:27:eb:47:8e:ed"
    PM2_MAC = "b8:27:eb:22:e2:9f"
    HOST_PORT = 1
    PM1_PORT = 2
    PM2_PORT = 3

    IPv4 = 0x8000
    ARP = 0x0806


    # スイッチが起動した時に呼ばれる
    def switch_ready(switchid)
        puts ""
        puts "--スイッチ捕捉--"
        puts "フローエントリを初期登録しました"
        @flag = 0
        @ipcache = []

        # ARP -> フラッディング
        send_flow_mod_add(
            switchid,
            :match => Match.new(:dl_type => ARP),
            :actions => SendOutPort.new(OFPP_FLOOD)
        )

        # PM1 -> hostに転送
        send_flow_mod_add(
            switchid,
            :match => Match.new(
                :dl_type => IPv4,
                :nw_src => PM1_IP
            ),
            :actions => SendOutPort.new(HOST_PORT),
            :priority => 0xfff2
        )

        # PM2 -> 送信元を書き換えてhostに転送
        action1 =
        [
            SetEthSrcAddr.new(PM1_MAC),
            SetIpSrcAddr.new(PM1),
            SendOutPort.new(HOST_PORT)
        ]
        send_flow_mod_add(
            switchid,
            :match => Match.new(
                :dl_type => IPv4,
                :nw_src => PM2_IP
            ),
            :actions => action1,
            :priority => 0xfff2
        )
    end

    # パケット着信があった時に呼ばれる
    def packet_in(switchid, message)
        srcip = message.ipv4_saddr.to_s
        dstip = message.ipv4_daddr.to_s
        if dstip == HOST_IP && !(@ipcache.index(srcip))
            @ipcache << srcip
            puts ""
            puts "未知のIPアドレス(#{{srcip}})からServer宛てのパケットがきました"
            loadbalance switchid, message
        end
    end

    # フローエントリーの削除
    def flow_removed(switchid, message)
        delip = message.match.nw_src.to_s
        puts ""
        puts "#{{delip}}のエントリが削除されました"
        @ipcache -= [delip]
    end

    private

    # 負荷分散処理
    def loadbalance(switchid, message)
        # flag=0 -> PM1に転送
        if @flag == 0
            send_flow_mod_add(
                switchid,
                :match => Match.new(
                    :dl_type => IPv4,
                    :nw_src => message.ipv4_saddr
                ),
                :actions => SendOutPort.new(PM1_PORT),
                :priority => 0xfff1,
                :idle_timeout => 300
            )
            send_packet_out(
                switchid,
                :data => message.data,
                :actions => SendOutPort.new(PM1_PORT)
            )
            puts "PM1に転送，フローテーブルへの登録"
            @flag = 1

        # flag=1 -> PM2に転送
        else
            action2 =
            [
                SetEthDstAddr.new(PM2_MAC),
                SetIpDstAddr.new(PM2_IP),
                SendOutPort.new(PM2_PORT)
            ]
            send_flow_mod_add(
                switchid,
                :match => Match.new(
                    :dl_type => IPv4,
                    :nw_src => message.ipv4_saddr
                ),
                :actions => action2,
                :priority => 0xfff1,
                :idle_timeout => 300
            )
            send_packet_out(
                switchid,
                :data => message.data,
                :actions => action2
            )
            puts "PM2に転送，フローテーブルへの登録"
            @flag = 0
        end
    end
end
