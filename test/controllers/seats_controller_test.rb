require 'test_helper'

class SeatsControllerTest < ActionDispatch::IntegrationTest
  def test_invalid_parameters
    # Test missing parameters
    assert_raise(ActionController::ParameterMissing) { post find_seats_path }

    # Test Invalid JSON input
    post find_seats_path, params: { no_of_seats: 1, seats_json: 'INVALID' }
    assert_equal 422, response.status

    # Test for required JSON keys
    post find_seats_path, params: { no_of_seats: 1, seats_json: '{"a": {}, "b": {}}' }
    assert response.body.include?('Required keys for JSON is missing. venue or seats')
  end

  def test_successful_find
    post find_seats_path, params: { no_of_seats: 1, seats_json: File.read('test/fixtures/files/valid_request.json') }, as: :json

    response_body = JSON.parse(response.body, symbolize_names: true)

    assert_equal 'a5', response_body.first[:id]
  end
end
