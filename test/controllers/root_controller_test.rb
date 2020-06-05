require 'test_helper'

class RootControllerTest < ActionDispatch::IntegrationTest
  def test_index
    get root_url

    assert response.body.include? '<div id="root">'
  end
end
