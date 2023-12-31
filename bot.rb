require "telegram/bot"

class Bot
  attr_reader :token, :game

  def initialize(token, game)
    @token = token
    @game = game
  end

  def run
    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        case message
        when Telegram::Bot::Types::Message
          handle_message(bot, message)
        when Telegram::Bot::Types::CallbackQuery
          handle_callback_query(bot, message)
        end
      end
    end
  end

  private

  def handle_message(bot, message)
    chat_id = message.chat.id.to_s
    case message.text
    when "/start"
      data_text = ["Привіт! 😇",
                   "Я бот, з яким можна зіграти в гру Tic Tac Toe.",
                   "Для початку гри виконайте команду /new_game 😉"]
      data_text.each do |text|
        bot.api.send_message(chat_id: message.chat.id, text: text)
        sleep(0.4)
      end
    when "/new_game"
      puts "New game started. chat_id: #{chat_id}"
      game.reset(message.chat.id)
      values_dict = game.values_dict
      all_moves_set = game.all_moves_set
      bot.api.send_message(chat_id: chat_id, text: 'Гра почалась',
                            reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: game.game_grid(values_dict)))
    else
      text = "#{Time.now} - #{message.from.first_name} - #{message.text}"
      puts text
    end
  end


  def handle_callback_query(bot, message)
    callback_data = message.data
    chat_id = message.from.id.to_s
    stored_data = GameState.load(chat_id)
    puts "Loaded stored_data: #{stored_data} chat_id: #{chat_id}"
    move, values_dict, all_moves_set = game.unpacking_values(callback_data, stored_data)

    puts "Loaded values_dict: #{values_dict} chat_id: #{chat_id}"
    puts "Loaded all_moves_set: #{all_moves_set} chat_id: #{chat_id}"

    if move && all_moves_set.include?(move)
      process_player_move(bot, message, move, values_dict, all_moves_set, chat_id)
    else
      puts "Invalid move or move already made. chat_id: #{chat_id}"
      begin
        bot.api.answer_callback_query(callback_query_id: message.id, text: "Цей хід вже зроблено. Спробуйте інший.")
      rescue Telegram::Bot::Exceptions::ResponseError => e
        puts "Failed to respond to callback query: #{e.message}"
      end
    end
  end

  def process_player_move(bot, message, move, values_dict, all_moves_set, chat_id)
    puts "Processing player move: #{move}"

    values_dict[move] = "❌"
    all_moves_set.delete(move)

    game_state = { all_moves_set: all_moves_set.to_a, values_dict: values_dict }
    puts "Game state before saving: #{game_state}"

    GameState.save(chat_id, game_state)

    if game.check_win(values_dict)[0]
      puts "Player wins!"
      end_game(bot, message, values_dict, chat_id)
    else
      puts "Processing bot move..."
      process_bot_move(bot, message, values_dict, all_moves_set, chat_id)
    end
  end


  def process_bot_move(bot, message, values_dict, all_moves_set, chat_id)
    puts "Processing bot move from process_bot_move... "

    bot_move = game.bot_ai(values_dict, all_moves_set)
    values_dict[bot_move] = '⭕'
    all_moves_set.delete(bot_move)
    game_state = { all_moves_set: all_moves_set.to_a, values_dict: values_dict } # Define game_state here

    puts "Game state before saving in process_bot_move: #{game_state}"
    GameState.save(chat_id, game_state)
    puts "Game state after saving in process_bot_move: #{GameState.load(chat_id)}"

    if game.check_win(values_dict)[0]
      end_game(bot, message, values_dict, chat_id)
    else
      update_game_grid(bot, message, values_dict, all_moves_set, chat_id)
    end
  end

  def end_game(bot, message, values_dict, chat_id)
    text = "Гру завершено. #{game.check_win(values_dict)[1]}"
    bot.api.send_message(chat_id: message.from.id, text: text)
    GameState.save(chat_id, {}) # Reset the game state
    bot.api.edit_message_reply_markup(chat_id: message.from.id, message_id: message.message.message_id,
                                      reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: game.game_grid(values_dict)))
  end

  def update_game_grid(bot, message, values_dict, all_moves_set, chat_id)
    bot.api.edit_message_reply_markup(chat_id: message.from.id, message_id: message.message.message_id,
                                      reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: game.game_grid(values_dict)))
  end
end
