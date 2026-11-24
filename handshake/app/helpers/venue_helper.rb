module VenueHelper
  def qr_svg(url)
    RQRCode::QRCode.new(url).as_svg(module_size: 5, standalone: true, use_path: true, viewbox: true,
                                     svg_attributes: { role: "img", "aria-label": "QR code" }).html_safe # rubocop:disable Rails/OutputSafety
  end

  def tent_url(venue) = scan_zone_url(public_code: venue.public_code, token: venue.qr_token)

  def week_label(venue)
    range = venue.week_range
    "#{range.first.strftime('%a %b %-d')} – #{range.last.strftime('%a %b %-d')}"
  end
end
