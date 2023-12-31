require_relative "game_state"
require_relative "game"
require_relative "bot"

token = "6960509334:AAF5NEfIDHLFACUVmwqnzbT1gF__H9CMgVA"
game = Game.new
bot = Bot.new(token, game)

bot.run
