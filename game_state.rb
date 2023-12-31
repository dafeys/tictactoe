require "sqlite3"
require "json"

class GameState
  DB_PATH = "game_states.sqlite"

  class << self
    def save(chat_id, game_state)
      puts "Saving game state: chat_id: #{chat_id}, game_state: #{game_state}"
      ensure_table_exists
      db.execute("INSERT OR REPLACE INTO game_states (chat_id, values_dict, all_moves_set)
                  VALUES (?, ?, ?)", [chat_id, game_state[:values_dict].to_json, game_state[:all_moves_set].to_json])
    end

    def load(chat_id)
      puts "Loading game state: chat_id: #{chat_id}"
      ensure_table_exists
      result = db.execute("SELECT values_dict, all_moves_set FROM game_states WHERE chat_id = ?", [chat_id]).first
      return nil unless result
      { values_dict: JSON.parse(result[0]), all_moves_set: Set.new(JSON.parse(result[1])) }
    end

    private

    def db
      @db ||= SQLite3::Database.new(DB_PATH)
    end

    def ensure_table_exists
      db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS game_states (
          chat_id INTEGER PRIMARY KEY,
          values_dict TEXT,
          all_moves_set TEXT
        );
      SQL
    end
  end
end
