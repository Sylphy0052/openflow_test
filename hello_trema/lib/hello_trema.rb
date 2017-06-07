class HelloTrema < Trema::Controller
  def start
     logger.info "Trema started."
  end

  def switch_ready(datapath_id)
    puts "Hello #{datapath_id.to_hex}!"
  end
end
