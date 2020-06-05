class SeatsController < ApplicationController
  before_action :validate_and_set_inputs

  AVAILABLE = 'AVAILABLE'.freeze
  NOT_AVAILABLE = 'NOT_AVAILABLE'.freeze

  def find
    build_venue
    find_best_available_seats
  end

  private

  # Validate the request params and input JSON
  def validate_and_set_inputs
    @no_of_seats = params.require(:no_of_seats)
    @seats_json = JSON.parse(params.require(:seats_json), symbolize_names: true)

    unless @seats_json.is_a?(Hash) && @seats_json[:venue].is_a?(Hash) && @seats_json[:seats].is_a?(Hash)
      render json: [t(:required_keys_missing)], status: :unprocessable_entity
      return
    end
    # Validate the number of seats requested
    validate_for_number_of_availability
  rescue JSON::ParserError => _ex
    render json: [t(:invalid_request)], status: :unprocessable_entity
  end

  # Validate the number of seats requested
  def validate_for_number_of_availability
    total_available_seats = @seats_json[:seats].select { |_key, seat| seat[:status] == AVAILABLE }.count

    render json: [t(:seats_not_available)], status: :unprocessable_entity if @no_of_seats.to_i > total_available_seats
  end

  # Based on the request JSON, build a venue
  # Venue is A X B Matrix by columns to rows
  # Rows are Alphabets and Columns are integers
  def build_venue
    number_of_rows = @seats_json[:venue][:layout].try(:[], :rows).to_i
    number_of_columns = @seats_json[:venue][:layout].try(:[], :columns).to_i
    rows = rows_as_alphabet(number_of_rows)

    @venue = []
    1.upto(number_of_rows).each do |row|
      row_index = row - 1
      @venue[row_index] = []
      row_id = "#{rows[row_index]}"
      1.upto(number_of_columns).each do |column|
        seat_id = "#{row_id}#{column}"
        @venue[row_index] << {
          id: seat_id,
          row: row_id,
          column: column,
          status: seats_available?(seat_id) ? AVAILABLE : NOT_AVAILABLE
        }
      end
    end
  end

  def seats_available?(seat_id)
    @seats_json[:seats][seat_id.to_sym].try(:[], :status) == AVAILABLE
  end

  def rows_as_alphabet(number_of_rows)
    1.upto(number_of_rows).map do |row_number|
      base26_char(row_number).map { |int_char| (int_char + 96).chr }.join('')
    end
  end

  def square_root(number, index)
    @square_result = {} unless defined? @sqare_result
    key = "#{number}-#{index}"
    return @square_result[key] if @square_result[key].present?

    result = 1
    while index > 0
      result = result * number
      index = index - 1
    end
    @square_result[key] = result
    result
  end

  # 0 is a, 26 iz z.
  # Converting to base 26
  def base26_char(number, result = [], index = 0)
    divident = number / square_root(26, index)
    if divident > 26
      base26_char(number, result, index + 1)
    else
      remainder = number - (square_root(26, index) * divident)

      if remainder.zero? && index > 0
        # Edge full divide
        result << divident - 1
        1.upto(index) do
          result << 26
        end
      else
        result << divident
      end
      base26_char(remainder, result) if remainder > 0
    end
    result
  end

  def find_best_available_seats
    @best_available_seats = []
    total_columns = @seats_json[:venue][:layout].try(:[], :columns).to_i
    middle = total_columns / 2.0
    middle_column = if total_columns % 2 == 0
                      [middle, middle + 1]
                    else
                      [middle.ceil]
                    end
    # Venue are sorted by index, 0 means front
    @venue.each do |row|
      left_index = (middle_column.first - 1).to_i
      right_index = (middle_column.size > 1 ? middle_column.last - 1 : middle_column.first - 1).to_i

      # Break the loop when got desired result
      break if @best_available_seats.size >= @no_of_seats.to_i
      # We are traversing from middle to both left and right ends
      0.upto(left_index).each do |index|

        l_index = left_index - index
        r_index = right_index + index

        l_seat = row[l_index]
        r_seat = row[r_index]

        # Break the loop when got desired result
        break if @best_available_seats.size >= @no_of_seats.to_i

        if l_seat && r_seat && l_seat[:id] == r_seat[:id]
          append_to_available_seats(l_seat)
        else
          append_to_available_seats(l_seat)
          append_to_available_seats(r_seat)
        end
      end
    end
  end

  def append_to_available_seats(seat)
    return if @best_available_seats.size >= @no_of_seats.to_i

    @best_available_seats << seat if seat && seats_available?(seat[:id])
  end
end
