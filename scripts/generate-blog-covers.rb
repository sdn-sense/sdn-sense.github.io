#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate deterministic SENSE title-card SVGs for posts that do not have
# event or presentation artwork. Missing cover metadata is added to the post
# front matter so the Blog, article layouts, and validators share one source.
require "cgi"
require "date"
require "fileutils"
require "json"
require "pathname"
require "yaml"

ROOT = Pathname.new(__dir__).join("..").expand_path
POSTS = ROOT.join("_posts")
OUTPUT = ROOT.join("assets/images/blog")
COVER_PREFIX = "/assets/images/blog/"
COVER_WIDTH = 1200
COVER_HEIGHT = 675

TYPE_STYLES = {
  "Release" => {
    kicker: "RELEASE NOTES",
    background: "#0d1b2f",
    accent: "#49b5ff",
    secondary: "#a9d9f7"
  },
  "Guide" => {
    kicker: "PRACTICAL GUIDE",
    background: "#005b96",
    accent: "#82dcff",
    secondary: "#c9efff"
  },
  "Presentation" => {
    kicker: "PRESENTATION",
    background: "#172942",
    accent: "#ffb454",
    secondary: "#ffe0b5"
  }
}.freeze

def front_matter(source, path)
  match = source.match(/\A---\s*\n(?<yaml>.*?)\n---\s*\n/m)
  abort "Missing front matter: #{path}" unless match

  data = YAML.safe_load(match[:yaml], permitted_classes: [Date, Time], aliases: true)
  abort "Invalid front matter: #{path}" unless data.is_a?(Hash)

  [match, data]
end

def post_type(data)
  categories = Array(data["categories"]) + Array(data["category"])
  return "Release" if categories.include?("releases")
  return "Guide" if categories.include?("guides")

  "Presentation"
end

def wrap_title(title, limit: 27)
  words = title.split
  lines = []
  current = []

  words.each do |word|
    candidate = (current + [word]).join(" ")
    if !current.empty? && candidate.length > limit
      lines << current.join(" ")
      current = [word]
    else
      current << word
    end
  end
  lines << current.join(" ") unless current.empty?
  lines
end

def title_geometry(lines)
  size = case lines.length
         when 1 then 96
         when 2 then 78
         when 3 then 64
         else 54
         end
  line_height = (size * 1.08).round
  block_height = line_height * lines.length
  start_y = 338 - (block_height / 2) + size
  [size, line_height, start_y]
end

def svg_for(data, type)
  title = data.fetch("title")
  style = TYPE_STYLES.fetch(type)
  lines = wrap_title(title)
  font_size, line_height, start_y = title_geometry(lines)
  published = data.fetch("date")
  date = published.respond_to?(:strftime) ? published.strftime("%B %-d, %Y") : published.to_s
  title_alt = "Title card for #{title}"

  title_lines = lines.each_with_index.map do |line, index|
    y = start_y + (index * line_height)
    %(<text x="82" y="#{y}" class="title">#{CGI.escapeHTML(line)}</text>)
  end.join("\n    ")

  <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="#{COVER_WIDTH}" height="#{COVER_HEIGHT}" viewBox="0 0 #{COVER_WIDTH} #{COVER_HEIGHT}" role="img" aria-labelledby="title description">
      <title id="title">#{CGI.escapeHTML(title_alt)}</title>
      <desc id="description">SENSE #{type.downcase} title card published #{CGI.escapeHTML(date)}.</desc>
      <rect width="1200" height="675" fill="#{style[:background]}"/>
      <rect width="18" height="675" fill="#{style[:accent]}"/>
      <g fill="none" stroke="#{style[:accent]}" stroke-width="3" opacity="0.19">
        <path d="M845 88 1018 172 906 308 1084 414 944 574"/>
        <path d="M1018 172 1136 88M906 308 1138 274M1084 414 1160 548"/>
        <circle cx="845" cy="88" r="14"/>
        <circle cx="1018" cy="172" r="18"/>
        <circle cx="906" cy="308" r="16"/>
        <circle cx="1084" cy="414" r="20"/>
        <circle cx="944" cy="574" r="14"/>
        <circle cx="1136" cy="88" r="10"/>
        <circle cx="1138" cy="274" r="11"/>
        <circle cx="1160" cy="548" r="12"/>
      </g>
      <g font-family="'Familjen Grotesk', 'IBM Plex Sans', system-ui, sans-serif">
        <text x="82" y="104" fill="#{style[:accent]}" font-size="24" font-weight="600" letter-spacing="4">#{style[:kicker]}</text>
        <g fill="#ffffff" font-size="#{font_size}" font-weight="600" letter-spacing="-1.5">
          #{title_lines}
        </g>
        <line x1="82" y1="550" x2="770" y2="550" stroke="#{style[:accent]}" stroke-width="3"/>
        <text x="82" y="600" fill="#{style[:secondary]}" font-size="26" font-weight="500">#{CGI.escapeHTML(date)}</text>
        <text x="1118" y="610" fill="#ffffff" font-size="30" font-weight="600" text-anchor="end" letter-spacing="3">SENSE</text>
      </g>
    </svg>
  SVG
end

FileUtils.mkdir_p(OUTPUT)
generated = 0
updated = 0

POSTS.glob("*").sort.each do |path|
  source = path.read
  match, data = front_matter(source, path)
  slug = path.basename.sub_ext("").to_s.sub(/^\d{4}-\d{2}-\d{2}-/, "")
  generated_path = "#{COVER_PREFIX}#{slug}.svg"
  existing_cover = data["cover"].to_s
  next unless existing_cover.empty? || existing_cover.start_with?(COVER_PREFIX)

  type = post_type(data)
  output_path = ROOT.join(generated_path.delete_prefix("/"))
  output_path.write(svg_for(data, type))
  generated += 1

  next unless existing_cover.empty?

  alt = "Title card for #{data.fetch('title')}"
  additions = [
    "cover: #{generated_path}",
    "cover_alt: #{alt.to_json}",
    "cover_width: #{COVER_WIDTH}",
    "cover_height: #{COVER_HEIGHT}"
  ].join("\n")
  replacement = "---\n#{match[:yaml]}\n#{additions}\n---\n"
  path.write(source.sub(match[0], replacement))
  updated += 1
end

puts "Generated #{generated} Blog title cards and updated #{updated} post files."
