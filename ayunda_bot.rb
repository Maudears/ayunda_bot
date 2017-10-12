require 'sinatra/base'
require 'active_support/all'
require 'telegram/bot'
require 'dotenv/load'
require 'active_record'
require 'date'
require 'rmagick'
require 'word_wrap'
require 'word_wrap/core_ext'

ActiveRecord::Base.establish_connection(
  :adapter  => "mysql2",
  :host     => "localhost",
  :username => "root",
  :password => "",
  :database => "blhbd"
)

load 'message_sender.rb'
load 'message_responder.rb'
load 'employee.rb'

class AyundaBot < Sinatra::Application
  set :server, :thin
  set :port, 6969
  set :bind, '0.0.0.0'

  def self.admins
    ['jsavigny']
  end

  def self.add_text_to_image(text, image_path)
    img = Magick::ImageList.new(image_path)
    img.resize_to_fill(600, 400)
    txt = Magick::Draw.new
    txt.pointsize = 25
    txt.gravity = Magick::CenterGravity
    txt.font_weight = Magick::BoldWeight
    txt.stroke = '#000000'
    txt.fill = '#ffffff'
    txt.annotate(img, 0, 0, 0, 0, text)

    output_path = image_path.chomp('.jpg') << '_' << DateTime.now.strftime('%d-%m') << '.jpg'
    img.write(output_path)

    output_path
  end

  def self.send_birthday_greeting
    usernames = ''
    names = ''
    @employees = Employee.find_each do |employee|
      if employee.dob.strftime('%d-%m') == DateTime.now.strftime('%d-%m')
        usernames << ' ' << employee.telegram_username
        names << employee.name << '\n'
      end
    end
    puts(names)

    unless usernames.empty? || names.empty?
      names.chop!

      text = 'Selamat ulang tahun yaa' << usernames << ', semoga panjang umur dan sehat selalu 	😘'
      message = { chat_id: ENV['GROUP_ID'], text: text }
      input_img = '~/Pictures/hbd.jpg'
      img = add_text_to_image(names, input_img)
      img_message = { chat_id: ENV['GROUP_ID'], photo: Faraday::UploadIO.new(img, 'image/jpeg') }

      MessageSender.send(img_message)
      MessageSender.send(message)
    end
  end

  def self.send_come_home
    usernames = ''
    self.admins.each do |username|
      usernames << '@' << username << ', '
    end

    2.times do
      usernames.chop!
    end

    message = { chat_id: ENV['GROUP_ID'], text: "#{usernames} sayang di mana? Cepet pulang dong, aku kangen niih 💋" }
    MessageSender.send(message)
  end

  get '/' do
    'Perahu Kertas ku kan melaju~'
  end

  # Sinatra~
  if app_file == $0
    Thread.start do
      begin
        Telegram::Bot::Client.run(ENV['BOT_TOKEN']) do |bot|
          bot.listen do |message|
            MessageResponder.perform_async(message, bot)
          end
        end
      rescue StandardError
        retry
      end
    end

    run!
  end
end
