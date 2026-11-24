require "test_helper"

# Chrome 158 rejects Capybara 3.40's wildcard storage clear between tests.
# Clear cookies directly instead, so each test starts as brand-new phones.
module ChromeResetWorkaround
  def execute_cdp(cmd, params = {})
    return super unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

    super("Network.clearBrowserCookies")
  end
end
Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeResetWorkaround)

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 390, 844 ]

  setup { Capybara.default_max_wait_time = 6 }

  def open_menu(item)
    find("summary", text: "Menu").click
    click_on item
  end

  def start_device(name, venue)
    using_session(name) do
      visit welcome_path
      check "adult"
      click_on "Get my code"
      fill_in "zone_number", with: venue.zones.first.zone_number
      fill_in "word", with: venue.table_word
      click_on "Use this zone"
      assert_text "Your code"
    end
  end

  def code_on_screen(name)
    using_session(name) { find("#my_code .code").text.delete(" ") }
  end
end
