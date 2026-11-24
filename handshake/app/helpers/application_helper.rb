module ApplicationHelper
  def nav_link(label, path, active)
    link_to label, path, "aria-current": (active ? "page" : nil)
  end

  # "47-12-83" with the zone pair highlighted.
  def code_tag(display)
    zone, rest = display.to_s.split("-", 2)
    tag.span(class: "code", "aria-label": display.to_s.chars.join(" ")) do
      safe_join([ tag.span(zone, class: "zz"), "-#{rest}" ])
    end
  end

  def countdown_ring(seconds:, total:, &block)
    tag.div(class: "code-wrap", data: { controller: "countdown", countdown_seconds_value: seconds, countdown_total_value: total }) do
      safe_join([
        tag.svg(class: "ring", viewBox: "0 0 100 100", "aria-hidden": "true") do
          safe_join([ tag.circle(class: "track", cx: 50, cy: 50, r: 45), tag.circle(class: "fill", cx: 50, cy: 50, r: 45, data: { countdown_target: "ring" }) ])
        end,
        tag.div(class: "code-center") { capture(&block) }
      ])
    end
  end

  # What the viewer may call another member: first name once you've both
  # reached step 1, otherwise their alias for this chat.
  def display_name(viewer, other)
    if RevealGrant.mutual_level(viewer, other) >= 1 && other.participant.first_name.present?
      "#{other.participant.first_name} (#{other.alias_name})"
    else
      other.alias_name
    end
  end

  def initials(name) = name.to_s.split.map(&:first).first(2).join.upcase

  def thread_title(membership)
    names = membership.others.map { display_name(membership, it) }
    names.empty? ? "Just you" : names.to_sentence
  end
end
