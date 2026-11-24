require "application_system_test_case"

# Real browsers, real Action Cable: separate sessions act as separate phones.
class HandshakeSystemTest < ApplicationSystemTestCase
  setup { @venue, = seed_venue(zone_number: 47) }

  def handshake!(a, b)
    a_code = code_on_screen(a)
    b_code = code_on_screen(b)
    using_session(a) do
      fill_in "code", with: b_code
      click_on "Connect"
      assert_text "Now they enter your code"
    end
    using_session(b) do
      fill_in "code", with: a_code
      click_on "Connect"
      assert_text "You're connected"
    end
    using_session(a) { assert_text "You're connected" } # pushed live to the first phone
  end

  def say(name, text)
    using_session(name) do
      fill_in "Message", with: text
      click_on "Send"
    end
  end

  test "two people connect with spoken codes and chat in real time" do
    start_device(:alice, @venue)
    start_device(:bob, @venue)
    handshake!(:alice, :bob)

    say(:alice, "Hi Bob!")
    using_session(:bob) { assert_selector ".msg .bubble", text: "Hi Bob!" }
    say(:bob, "Hi! Nice to meet you")
    using_session(:alice) do
      assert_selector ".msg .bubble", text: "Nice to meet you"
      assert_selector ".msg.mine .bubble", text: "Hi Bob!"
    end
  end

  test "add someone: thread code, mutual entry and unanimous approval" do
    start_device(:alice, @venue)
    start_device(:bob, @venue)
    handshake!(:alice, :bob)
    say(:alice, "before carol")
    start_device(:carol, @venue)

    using_session(:alice) do
      open_menu "Add someone"
      @thread_code = find("#add_in_code .code").text.delete(" ")
    end
    carol_code = code_on_screen(:carol)
    using_session(:carol) do
      fill_in "code", with: @thread_code
      click_on "Connect"
      assert_text "Now they enter your code"
    end
    using_session(:alice) do
      fill_in "code", with: carol_code
      click_on "Ask the group"
    end
    using_session(:carol) { assert_text "Asking the group" }
    using_session(:bob) do
      assert_text "Someone new wants to join"
      click_on "Yes"
    end
    using_session(:carol) do
      assert_text "joined."
      assert_no_text "before carol" # newcomers see only what comes after
    end
    say(:carol, "Hello both")
    using_session(:bob) { assert_selector ".msg .bubble", text: "Hello both" }
  end

  test "reveal ladder: names appear only after both choose step 1" do
    start_device(:alice, @venue)
    start_device(:bob, @venue)
    using_session(:alice) do
      click_on "Me"
      fill_in "First name", with: "Alice"
      click_on "Save"
      click_on "Code"
    end
    handshake!(:alice, :bob)

    using_session(:bob) do
      open_menu "People and reveals"
      within(".ladder li", match: :first) { click_on "Share" }
      assert_text "you're ready, waiting for them"
      assert_no_text "Alice"
    end
    using_session(:alice) do
      open_menu "People and reveals"
      assert_text "they're ready if you are"
      within(".ladder li", match: :first) { click_on "Share" }
      assert_text "Shared with each other: First name and photo"
    end
    using_session(:bob) do
      visit current_path
      assert_text "First name: Alice"
    end
  end

  test "ending a chat makes it vanish for both" do
    start_device(:alice, @venue)
    start_device(:bob, @venue)
    handshake!(:alice, :bob)

    using_session(:bob) do
      find("summary", text: "Menu").click
      accept_confirm { click_on "End chat for both of us" }
      assert_text "It's gone for both of you"
    end
    using_session(:alice) do
      assert_text "This chat has ended"
      visit chat_threads_path
      assert_text "No chats yet"
    end
  end
end
