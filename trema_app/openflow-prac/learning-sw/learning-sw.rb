require "fdb"

 class LearningSwitch < Controller
  add_timer_event :age_fdb, 5, :periodic
	def start
    @fdb = FDB.new
  end

  def packet_in datapath_id, message
    @fdb.learn message.macsa, message.in_port
    port_no = @fdb.port_no_of( message.macda )
    if port_no
       flow_mod datapath_id, message, port_no
       packet_out datapath_id, message, port_no
     else
       flood datapath_id, message
     end
   end

   def age_fdb
     @fdb.age
   end

   private

   def flow_mod datapath_id, message, port_no
     send_flow_mod_add(
       datapath_id,
       :match => ExactMatch.from( message ),
       :actions => ActionOutput.new( :port => port_no )
     )
   end

   def packet_out datapath_id, message, port_no
     send_packet_out(
       datapath_id,
       :packet_in => message,
       :actions => ActionOutput.new( :port => port_no )
     )
   end

   def flood datapath_id, message
     packet_out datapath_id, message, OFPP_FLOOD
   end
 end