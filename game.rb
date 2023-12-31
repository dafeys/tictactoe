class Game
  attr_accessor :values_dict, :all_moves_set

  def initialize
    reset(1)
  end

  def reset(chat_id)
    @chat_id = chat_id
    @all_moves_set = Set.new(["1", "2", "3", "4", "5", "6", "7", "8", "9"])
    @values_dict = {"1"=>" ", "2"=>" ", "3"=>" ", "4"=>" ", "5"=>" ", "6"=>" ", "7"=>" ", "8"=>" ", "9"=>" "}
    GameState.save(@chat_id, { all_moves_set: @all_moves_set.to_a, values_dict: @values_dict })
  end

  def game_grid(values_dict)
    grid = [
      [{text: show_value(values_dict, "1"), callback_data: "1"}, {text: show_value(values_dict, "2"), callback_data: "2"}, {text: show_value(values_dict, "3"), callback_data: "3"}],
      [{text: show_value(values_dict, "4"), callback_data: "4"}, {text: show_value(values_dict, "5"), callback_data: "5"}, {text: show_value(values_dict, "6"), callback_data: "6"}],
      [{text: show_value(values_dict, "7"), callback_data: "7"}, {text: show_value(values_dict, "8"), callback_data: "8"}, {text: show_value(values_dict, "9"), callback_data: "9"}]
    ]
    grid
  end

  def show_value(values_dict, index)
    value = values_dict[index.to_s]
    value.to_s
  end

  def packaging_values(values_dict, all_moves_set)
    value_str = ""
    values_dict.each { |key, value| value_str += value.to_s }
    value_str += "-"
    all_moves_set.each { |move| value_str += move.to_s }
    value_str
  end

  def unpacking_values(callback_data, stored_data)
    move = callback_data
    if stored_data
      values_dict = stored_data[:values_dict]
      all_moves_set = stored_data[:all_moves_set]
    else
      values_dict = {
        "1" => " ", "2" => " ", "3" => " ",
        "4" => " ", "5" => " ", "6" => " ",
        "7" => " ", "8" => " ", "9" => " "
      }
      all_moves_set = Set.new(%w[1 2 3 4 5 6 7 8 9])
    end
    [move, values_dict, all_moves_set]
  end

  def check_win(values_dict)
    win_conditions = [
      ["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], # Rows
      ["1", "4", "7"], ["2", "5", "8"], ["3", "6", "9"], # Columns
      ["1", "5", "9"], ["3", "5", "7"]                   # Diagonals
    ]

    win_conditions.each do |condition|
      return true, "Ви виграли" if win?(values_dict, condition, "❌")
      return true, "Ви програли" if win?(values_dict, condition, "⭕")
    end

    return true, "Нічия" if values_dict.values.none? { |value| value == " " }

    [false, "none"]
  end

  def win?(values_dict, condition, symbol)
    condition.all? { |position| values_dict[position] == symbol }
  end

  def bot_ai(values_dict, all_moves_set)
    check_data = [
      ["1", "2", "3"],
      ["4", "5", "6"],
      ["7", "8", "9"],
      ["1", "4", "7"],
      ["2", "5", "8"],
      ["3", "6", "9"],
      ["1", "5", "9"],
      ["3", "5", "7"]
    ]

    ["⭕", "❌"].each do |symbol|
      check_data.each do |i|
        return i[2] if values_dict[i[0]] == values_dict[i[1]] && values_dict[i[1]] == symbol && all_moves_set.include?(i[2])
        return i[1] if values_dict[i[0]] == values_dict[i[2]] && values_dict[i[2]] == symbol && all_moves_set.include?(i[1])
        return i[0] if values_dict[i[1]] == values_dict[i[2]] && values_dict[i[2]] == symbol && all_moves_set.include?(i[0])
      end
    end

    all_moves_set.to_a.sample
  end
end
