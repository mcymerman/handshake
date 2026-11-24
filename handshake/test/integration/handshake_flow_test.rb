require "test_helper"

class HandshakeFlowTest < ActionDispatch::IntegrationTest
  setup { @venue, = seed_venue(zone_number: 47) }

  def device_in_zone
    session = open_session
    session.post welcome_path, params: { adult: "1" }
    session.post zone_path, params: { zone_number: 47, word: @venue.table_word }
    session.get root_path
    display = session.css_select("#my_code .code").first.text.delete(" ")
    [ session, display ]
  end

  test "two phones swap codes and both land in the same private chat" do
    alice, alice_code = device_in_zone
    bob, bob_code = device_in_zone

    alice.post code_entries_path, params: { code: bob_code }, as: :turbo_stream
    assert_match "Now they enter your code", alice.response.body

    bob.post code_entries_path, params: { code: alice_code }, as: :turbo_stream
    assert_match "visit", bob.response.body
    thread = ChatThread.last
    alice.get chat_thread_path(thread)
    assert_equal 200, alice.response.status
    bob.post chat_thread_messages_path(thread), params: { message: { body: "hello there" } }, as: :turbo_stream
    alice.get chat_thread_path(thread)
    assert_match "hello there", alice.response.body
  end

  test "outsiders can't open, post to, or even confirm a chat" do
    alice, alice_code = device_in_zone
    bob, bob_code = device_in_zone
    alice.post code_entries_path, params: { code: bob_code }, as: :turbo_stream
    bob.post code_entries_path, params: { code: alice_code }, as: :turbo_stream
    thread = ChatThread.last

    mallory, = device_in_zone
    mallory.get chat_thread_path(thread)
    assert_equal 302, mallory.response.status
    mallory.post chat_thread_messages_path(thread), params: { message: { body: "let me in" } }, as: :turbo_stream
    assert_equal 404, mallory.response.status
    refute Message.where(chat_thread: thread).map(&:body).include?("let me in")
  end

  test "crafted requests get a polite answer, not a server error" do
    alice, alice_code = device_in_zone
    bob, bob_code = device_in_zone
    alice.post code_entries_path, params: { code: bob_code }, as: :turbo_stream
    bob.post code_entries_path, params: { code: alice_code }, as: :turbo_stream
    thread = ChatThread.last
    other = thread.memberships.second

    alice.patch chat_thread_person_path(thread, other)
    assert_equal 302, alice.response.status
    alice.patch chat_thread_person_path(thread, other), params: { level: "lots" }
    assert_equal 302, alice.response.status
  end

  test "ending a one-to-one from the web removes it for both" do
    alice, alice_code = device_in_zone
    bob, bob_code = device_in_zone
    alice.post code_entries_path, params: { code: bob_code }, as: :turbo_stream
    bob.post code_entries_path, params: { code: alice_code }, as: :turbo_stream
    thread = ChatThread.last

    bob.delete chat_thread_path(thread)
    refute ChatThread.exists?(thread.id)
    alice.get chat_threads_path
    refute_match thread.id, alice.response.body
  end

  test "reports keep minimal data and attach messages only when asked" do
    alice, alice_code = device_in_zone
    bob, bob_code = device_in_zone
    alice.post code_entries_path, params: { code: bob_code }, as: :turbo_stream
    bob.post code_entries_path, params: { code: alice_code }, as: :turbo_stream
    thread = ChatThread.last
    bob.post chat_thread_messages_path(thread), params: { message: { body: "rude words" } }, as: :turbo_stream
    target = Message.find_by(chat_thread: thread, kind: "text").membership

    alice.post chat_thread_reports_path(thread), params: { report: { membership_id: target.id, reason: "harassment", include_evidence: "0" } }
    assert_nil Report.order(:created_at).last.evidence
    alice.post chat_thread_reports_path(thread), params: { report: { membership_id: target.id, reason: "harassment", include_evidence: "1" } }
    assert_match "rude words", Report.order(:created_at).last.evidence
  end
end
