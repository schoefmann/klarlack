require 'spec/spec_helper'

describe Varnish::Client do
  
  before(:each) do
    @varnish = Varnish::Client.new "127.0.0.1:6082"
  end

  describe '(connection handling)' do

    it 'should not be connected on object instantiation' do
      @varnish.connected?.should be_false
    end

    it 'should not raise an error when trying to disconnect a non-connected client' do
      lambda { @varnish.disconnect }.should_not raise_error
    end

    it 'should automatically connect when a command is issued' do
      @varnish.ping
      @varnish.connected?.should be_true
    end

    it 'should be possible to disable timeouts' do
      Varnish::SocketFactory::Timer.should_not_receive(:timeout).and_return("200 0")
      @varnish.timeout = nil
      @varnish.ping
    end

    it '#disconnect should close the connection' do
      @varnish.ping
      @varnish.connected?.should be_true
      @varnish.disconnect
      @varnish.connected?.should be_false
    end

    it 'given keep_alive is set, the connection should be kept alive with pings' do
      @varnish.keep_alive = true
      @varnish.should_receive :ping
      @varnish.send :connect
    end

    it 'given keep_alive is not set, no pings should be sent to varnishd' do
      @varnish.keep_alive = false
      @varnish.should_not_receive :ping
      @varnish.send :connect
    end

    it '#server should return the host and port for the connection' do
      @varnish.host = "foohost"
      @varnish.port = 1234
      @varnish.server.should == "foohost:1234"
    end

    it '#server= should set the host and port for the connection' do
      @varnish.server = "blahost:9876"
      @varnish.host.should == "blahost"
      @varnish.port.should == 9876
    end

  end

  describe '(commands)' do

    # ... the specs for #param, #purge and #vcl could be better ...

    it '#param should send the param command to varnishd' do
      @varnish.param(:show).should_not be_empty
    end

    it '#purge should send the purge command to varnishd' do
      @varnish.should_receive(:cmd).with("purge.url", ".*")
      @varnish.purge :url, '.*'
      @varnish.should_receive(:cmd).with("purge RxRequest", "foo")
      @varnish.purge :RxRequest, "foo"
    end

    it '#vcl should send the vcl command to varnishd' do
      @varnish.vcl(:list).should_not be_empty
    end

    it '#ping should send a ping to the server and return a string containing the response' do
      @varnish.ping.should =~ /^PONG \d+/
    end


    it '#status should return a string explaining the daemons status' do
      @varnish.status.should =~ /running|stopped|stopping|starting/
    end

    it "#stats should return a hash containing status information" do
      stats = @varnish.stats
      stats.should_not be_empty
      stats.values.each {|v| v.should be_kind_of(Fixnum) }
      stats.keys.each {|k| k.should_not be_empty }
    end

  end
  
  describe '(daemon lifecycle)' do
    
    it '#start, #stop, #running?, #stopped? should bahave as advertised' do
      ensure_stopped # issues #stop
      @varnish.stopped?.should be_true
      @varnish.running?.should be_false
      ensure_started # issues #start
      @varnish.stopped?.should be_false
      @varnish.running?.should be_true
    end
    
    it 'starting an already started daemon should raise an error' do
      ensure_started
      lambda { @varnish.start }.should raise_error(Varnish::Error)
    end
    
    it 'stopping an already stopped daemon should raise an error' do
      ensure_stopped
      lambda { @varnish.stop }.should raise_error(Varnish::Error)
    end
    
  end
  
  def ensure_started
    @varnish.start if @varnish.stopped?
    while(!@varnish.running?) do sleep 0.1 end
  end
  
  def ensure_stopped
    @varnish.stop if @varnish.running?
    while(!@varnish.stopped?) do sleep 0.1 end
  end

end
