%w{ yaml erb pony open-uri }.each { |d| require d }

class AmIAlive
  class << self
    def configure!
      @config ||= YAML.load( ERB.new(File.read('config.yml')).result )
      Pony.options = @config[:mail]
      self
    end

    def run
      @config || configure!
      while sleep(@config[:sleep_time])
        @config[:urls].each { |url| check url }
      end
    end

    def failure?(url, first_failure_only=false)
      fail_num = @failures[url] || 0
      first_failure_only ? fail_num == @config[:tolerated_failures] + 1 : fail_num > @config[:tolerated_failures]
    end

    def raise_alarm(url, status)
      if failure? url, @config[:send_alarms_only_once]
        send_to_everyone('ALARM!!', "There is a problem (#{status}) with #{url}")
      end
    end

    def recover(url)
      send_to_everyone('RECOVER! \o/', "Everything's OK now with #{url}")
    end

    def check(url)
      @failures ||= {}
      status = begin
        open(url).status.first
      rescue Exception => e
        e.message
      end
      if status == '200'
        recover url if failure? url
        @failures[url] = 0
      else
        @failures[url] = (@failures[url] ? @failures[url] + 1 : 1)
        # no need to count to infinity
        @failures[url] = @config[:tolerated_failures] + 1 if @failures[url]*2 < @config[:tolerated_failures]
        raise_alarm(url, status) if failure? url
      end
    end

    def send_to_everyone(subject='', body='')
      @config[:emails].each do |email|
        Pony.mail(:to => email, :subject => subject, :body => body)
      end
    end
  end
end

if $0 == __FILE__
  STDOUT.sync = true
  AmIAlive.run
end
