# Drives three headless Chrome "phones" through every flow against a running
# development server and saves screenshots for the user guide.
#
#   ADMIN_PASSWORD=<same as the dev server's> bin/rails runner script/guide_screenshots.rb http://localhost:3100 /tmp/hs-shots
#
# Uses disposable browser profiles; never touches anyone's real browser.
require "selenium-webdriver"
require "fileutils"
require "tmpdir"

BASE = ARGV[0] || "http://localhost:3100"
OUT = ARGV[1] || "/tmp/hs-shots"
ZONE = 12 # the always-open conference zone from db/seeds.rb
FileUtils.mkdir_p(OUT)
WORD = Zone.find_by!(zone_number: ZONE).venue.table_word

def browser(width, height)
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  if width < 500
    # True phone viewport (desktop Chrome can't shrink a window below 500px).
    options.add_emulation(device_metrics: { width:, height:, pixelRatio: 2, touch: true },
                          user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1")
  else
    options.add_argument("--window-size=#{width},#{height}")
  end
  options.add_argument("--user-data-dir=#{Dir.mktmpdir('hs-chrome')}")
  options.add_argument("--hide-scrollbars")
  driver = Selenium::WebDriver.for(:chrome, options:)
  driver.manage.timeouts.implicit_wait = 6
  driver
end

def shot(driver, name)
  sleep 0.6
  driver.save_screenshot(File.join(OUT, "#{name}.png"))
  puts "saved #{name}"
end

def wait_for(driver, text, seconds = 8)
  Selenium::WebDriver::Wait.new(timeout: seconds).until { driver.find_element(tag_name: "body").text.include?(text) }
end

def click_text(driver, text)
  driver.find_elements(xpath: "//*[self::a or self::button or self::input[@type='submit'] or self::summary][normalize-space(.)='#{text}' or @value='#{text}']").first.click
end

def start(driver, name = nil)
  driver.navigate.to("#{BASE}/welcome")
  shot(driver, "01-welcome") if name
  driver.find_element(id: "adult").click
  click_text(driver, "Get my code")
  wait_for(driver, "Where are you?")
  shot(driver, "02-zone") if name
  driver.find_element(id: "zone_number").send_keys(ZONE.to_s)
  driver.find_element(id: "word").send_keys(WORD)
  click_text(driver, "Use this zone")
  wait_for(driver, "Your code")
end

def code_of(driver) = driver.find_element(css: "#my_code .code").text.delete(" ")

def enter_code(driver, code, button = "Connect")
  field = driver.find_element(id: "code")
  field.clear
  field.send_keys(code)
  click_text(driver, button)
end

def menu(driver, item)
  driver.find_element(css: "summary").click
  click_text(driver, item)
end

def say(driver, text)
  box = driver.find_element(id: "message_body")
  box.send_keys(text)
  click_text(driver, "Send")
  sleep 0.4
end

alice = browser(390, 844)
bob = browser(390, 844)
carol = browser(390, 844)
desk = browser(1280, 860)

begin
  start(alice, :alice)
  shot(alice, "03-home-code")
  start(bob)
  start(carol)

  # Handshake
  enter_code(alice, code_of(bob))
  wait_for(alice, "Now they enter your code")
  shot(alice, "04-waiting-for-them")
  enter_code(bob, code_of(alice))
  wait_for(alice, "You're connected")
  wait_for(bob, "You're connected")
  say(alice, "Hi! Great talk earlier 👋")
  say(bob, "Thanks! Glad we didn't have to swap numbers")
  say(alice, "Same. Want to grab the 2pm session together?")
  wait_for(bob, "2pm session")
  shot(bob, "05-chat")
  bob.find_element(css: "summary").click
  shot(bob, "06-chat-menu")
  bob.find_element(css: "summary").click

  # Typo message
  carol.navigate.to("#{BASE}/")
  enter_code(carol, "#{ZONE}-00-00")
  sleep 0.6
  shot(carol, "07-typo")

  # My details + reveal ladder
  alice.navigate.to("#{BASE}/profile/edit")
  alice.find_element(id: "participant_first_name").send_keys("Alice")
  alice.find_element(id: "participant_social_handles").send_keys("@alice.builds")
  shot(alice, "08-my-details")
  click_text(alice, "Save")
  bob.navigate.to("#{BASE}/profile/edit")
  bob.find_element(id: "participant_first_name").send_keys("Ben")
  click_text(bob, "Save")
  alice.navigate.to("#{BASE}/chats")
  shot(alice, "09-chats-list")
  alice.find_element(css: ".chat-list a").click
  wait_for(alice, "2pm session")
  thread_url = alice.current_url
  alice.navigate.to("#{thread_url}/people")
  alice.find_element(css: ".ladder li button").click
  wait_for(alice, "you're ready, waiting for them")
  bob.navigate.to("#{thread_url}/people")
  wait_for(bob, "they're ready if you are")
  shot(bob, "10-reveal-offer")
  bob.find_element(css: ".ladder li button").click
  wait_for(bob, "First name: Alice")
  shot(bob, "11-reveal-shared")

  # Add someone (add-in code) with approval
  alice.navigate.to("#{thread_url}/add_in")
  wait_for(alice, "They enter this code")
  thread_code = alice.find_element(css: "#add_in_code .code").text.delete(" ")
  shot(alice, "12-add-someone")
  carol.navigate.to("#{BASE}/")
  enter_code(carol, thread_code)
  wait_for(carol, "Now they enter your code")
  enter_code(alice, code_of(carol), "Ask the group")
  wait_for(carol, "Asking the group")
  shot(carol, "13-newcomer-waiting")
  bob.navigate.to(thread_url)
  wait_for(bob, "Someone new wants to join")
  shot(bob, "14-approve-newcomer")
  click_text(bob, "Yes")
  wait_for(carol, "joined.")
  say(carol, "Hi both! Thanks for letting me in")
  wait_for(bob, "letting me in")
  shot(carol, "15-group-chat-newcomer")

  # Group handshake
  alice.navigate.to("#{thread_url}/group_handshake")
  shot(alice, "16-group-handshake-start")
  click_text(alice, "Start a 2-minute group handshake")
  wait_for(alice, "Anyone nearby can enter")
  shot(alice, "17-group-handshake-code")

  # Report
  carol.navigate.to("#{thread_url}/reports/new")
  shot(carol, "18-report")

  # Big code
  carol.navigate.to("#{BASE}/my_code/big")
  shot(carol, "19-big-code")

  # Demo mode
  dana = browser(390, 844)
  start(dana)
  click_text(dana, "Try with a demo friend")
  wait_for(dana, "Your demo friend's code")
  dana.execute_script("document.querySelector('#code').scrollIntoView({block: 'start'})")
  shot(dana, "20-demo-friend")
  dana.quit

  # Desktop views
  desk.navigate.to("#{BASE}/dash/dev-conf/tent")
  shot(desk, "21-table-tent")
  desk.navigate.to("#{BASE}/dash/dev-conf")
  shot(desk, "22-staff-dashboard")
  desk.navigate.to("#{BASE}/dash/dev-conf/live")
  shot(desk, "23-live-display")
  start(desk)
  shot(desk, "24-desktop-home")
  desk.navigate.to("#{BASE}/how")
  shot(desk, "25-how-it-works")
  desk.navigate.to("#{BASE}/privacy")
  shot(desk, "26-privacy")

  # Admin (basic auth in the URL is fine for a local headless check)
  # Same ADMIN_PASSWORD the dev server was started with (local only).
  password = ENV.fetch("ADMIN_PASSWORD")
  admin_base = BASE.sub("://", "://admin:#{password}@")
  carol.navigate.to("#{thread_url}/reports/new")
  carol.find_element(css: "input[value='harassment']").click
  carol.find_element(id: "report_include_evidence").click
  click_text(carol, "Send report")
  wait_for(carol, "Thanks for telling us")
  shot(carol, "27-report-thanks")
  desk.navigate.to("#{admin_base}/admin/reports")
  shot(desk, "28-admin-reports")
  desk.navigate.to("#{admin_base}/admin/metrics")
  shot(desk, "29-admin-metrics")

  # End chat flow (1:1 between two fresh phones)
  erin = browser(390, 844)
  fred = browser(390, 844)
  start(erin)
  start(fred)
  enter_code(erin, code_of(fred))
  wait_for(erin, "Now they enter your code")
  enter_code(fred, code_of(erin))
  wait_for(fred, "You're connected")
  wait_for(erin, "You're connected")
  fred.find_element(css: "summary").click
  fred.find_element(xpath: "//button[contains(., 'End chat')]").click
  fred.switch_to.alert.accept
  wait_for(erin, "This chat has ended")
  shot(erin, "30-chat-ended-other-side")
  erin.quit
  fred.quit
ensure
  [ alice, bob, carol, desk ].each { it&.quit }
end
