# Builds the user guide from screenshots:
#   ruby script/build_guide.rb /tmp/hs-shots
# 1. converts PNG screenshots to compact JPEGs in docs/handshake/guide/img/
# 2. writes guide-standalone.html with the images embedded (one file to email)
# 3. prints guide.pdf with headless Chrome
# Needs ImageMagick (`magick`) and Google Chrome.
require "base64"
require "fileutils"
require "tmpdir"

shots = ARGV[0] || "/tmp/hs-shots"
guide_dir = File.expand_path("../../docs/handshake/guide", __dir__)
img_dir = File.join(guide_dir, "img")
FileUtils.mkdir_p(img_dir)

Dir[File.join(shots, "*.png")].sort.each do |png|
  name = File.basename(png, ".png")
  width = File.basename(png).match?(/\A(21|22|23|24|25|26|28|29)-/) ? 1200 : 520
  out = File.join(img_dir, "#{name}.jpg")
  system("magick", png, "-resize", "#{width}x>", "-strip", "-quality", "78", out, exception: true)
end

html = File.read(File.join(guide_dir, "guide.html"))
standalone = html.gsub(%r{src="img/([\w-]+\.jpg)"}) do
  data = Base64.strict_encode64(File.binread(File.join(img_dir, Regexp.last_match(1))))
  %(src="data:image/jpeg;base64,#{data}")
end
standalone_path = File.join(guide_dir, "guide-standalone.html")
File.write(standalone_path, standalone)

chrome = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
pdf_path = File.join(guide_dir, "guide.pdf")
profile = Dir.mktmpdir("hs-pdf") rescue "/tmp/hs-pdf-profile"
system(chrome, "--headless=new", "--disable-gpu", "--user-data-dir=#{profile}", "--no-pdf-header-footer",
       "--print-to-pdf=#{pdf_path}", "file://#{standalone_path}", exception: true, err: File::NULL)

puts "images: #{Dir[File.join(img_dir, '*.jpg')].size}"
puts "standalone: #{(File.size(standalone_path) / 1024.0 / 1024).round(2)} MB"
puts "pdf: #{(File.size(pdf_path) / 1024.0 / 1024).round(2)} MB"
