class MessageResponder
  include SuckerPunch::Job
  workers 5

  attr_accessor :bot

  def perform(message, bot)
    @bot = bot

    return unless message

    text = message.text.sub(ENV['BOT_USERNAME'], '')
    case text
    when '/hi'
      if is_admin?(message)
        text = 'Halo sayangku ' << message.from.first_name << ' 😍'
      else
        text = 'Apaan sih! Kamu bukan Julio! 😡'
      end
      reply(message, text)
    when '/kiss'
      if is_admin?(message)
        text = '💋💋💋'
      else
        text = 'Apaan sih! Kamu bukan Julio! 😡'
      end
      reply(message, text)
    when '/help'
      text = 'Halo! Bot ini sedang dalam tahap pengembangan, jika ada kritik dan saran, silakan kirim ke @jsavigny'
      reply(message, text)
    else
      text = 'Maafin ya aku ga ngerti apa yang kamu mau 😞'
      reply(message, text)
    end
  end

  private

  def reply(message, text)
    send(chat_id: message.chat.id, text: text, reply_to_message_id: message.message_id)
  end

  def send(options = {})
    MessageSender.perform_async(options)
  end

  def is_admin?(message)
    message.from.username.in?(AyundaBot.admins)
  end
end
