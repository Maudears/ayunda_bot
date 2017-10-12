require 'sucker_punch'
require 'telegram/bot'
require 'dotenv/load'

class MessageSender
  include SuckerPunch::Job

  def self.send(message)
    self.perform_async(message)
  end

  def perform(options = {})
    results = {}
    Telegram::Bot::Client.run(ENV['BOT_TOKEN']) do |bot|
      if options[:text].present?
        options[:text].scan(/.{1,4000}/m) do |text|
          begin
            options[:text] = text
            results = bot.api.send_message(options)
            sleep(0.1)
          rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
            sleep(1.3)
            retry
          rescue Telegram::Bot::Exceptions::ResponseError => e
            if e.message =~ /error_code: .429./
              sleep(3)
            end
            retry unless e.message =~ /error_code: .(400|403|409)./
          end
        end
      elsif options[:photo].present?
        begin
          results = bot.api.send_photo(options)
          sleep(0.1)
        rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
          sleep(1.3)
          retry
        rescue Telegram::Bot::Exceptions::ResponseError => e
          if e.message =~ /error_code: .429./
            sleep(3)
          end
          retry unless e.message =~ /error_code: .(400|403|409)./
        end
      end
    end
    results
  end
end
