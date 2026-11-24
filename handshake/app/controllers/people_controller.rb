# People in this chat and the pairwise reveal ladder.
class PeopleController < ApplicationController
  include ThreadScoped

  def index
    @others = @membership.others.includes(:participant).to_a
  end

  def update
    other = @membership.others.find_by(id: params[:id])
    return redirect_to(chat_thread_people_path(@thread), alert: "They're not in this chat any more.") unless other

    RevealGrant.offer!(from: @membership, to: other, level: params[:level])
    DemoPartner.match_reveal(from: @membership, to: other) if demo_mode?
    redirect_to chat_thread_people_path(@thread, anchor: "person_#{other.id}")
  rescue ArgumentError, TypeError
    redirect_to chat_thread_people_path(@thread), alert: "Reveal steps go one at a time."
  end
end
