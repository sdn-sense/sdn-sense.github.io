#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "nokogiri"
require "pathname"
require "uri"

site = Pathname.new(ARGV.fetch(0, "_site")).expand_path
pages = site.glob("**/*.html")
abort "No rendered HTML pages found in #{site}" if pages.empty?

expected_origin = "https://sdn-sense.dev"
errors = []

def schema_types(value, found = [])
  case value
  when Hash
    type = value["@type"]
    found.concat(Array(type)) if type
    value.each_value { |child| schema_types(child, found) }
  when Array
    value.each { |child| schema_types(child, found) }
  end
  found
end

pages.each do |path|
  relative_path = path.relative_path_from(site)
  document = Nokogiri::HTML(path.read)
  failures = []

  descriptions = document.css('meta[name="description"]')
  canonicals = document.css('link[rel="canonical"]')
  failures << "expected exactly one meta description" unless descriptions.length == 1
  failures << "expected exactly one canonical link" unless canonicals.length == 1

  description = descriptions.first&.[]("content").to_s.strip
  failures << "description is too short (#{description.length} characters)" if description.length < 40
  failures << "description is too long (#{description.length} characters)" if description.length > 180

  canonical = canonicals.first&.[]("href").to_s
  begin
    canonical_uri = URI.parse(canonical)
    failures << "canonical URL must use HTTPS" unless canonical_uri.scheme == "https"
    failures << "canonical URL must use the production origin" unless canonical.start_with?(expected_origin)
  rescue URI::InvalidURIError
    failures << "canonical URL is invalid: #{canonical}"
  end

  {
    'meta[property="og:title"]' => "Open Graph title",
    'meta[property="og:description"]' => "Open Graph description",
    'meta[property="og:url"]' => "Open Graph URL",
    'meta[property="og:image"]' => "Open Graph image",
    'meta[name="twitter:card"], meta[property="twitter:card"]' => "Twitter card",
    'meta[name="twitter:image"], meta[property="twitter:image"]' => "Twitter image"
  }.each do |selector, label|
    element = document.at_css(selector)
    failures << "missing #{label}" if element&.[]("content").to_s.strip.empty?
  end

  og_url = document.at_css('meta[property="og:url"]')&.[]("content").to_s
  failures << "Open Graph URL does not match canonical" unless og_url == canonical

  og_image = document.at_css('meta[property="og:image"]')&.[]("content").to_s
  failures << "Open Graph image must use HTTPS" unless og_image.start_with?("https://")

  document.css('script[type="application/ld+json"]').each_with_index do |script, index|
    JSON.parse(script.text)
  rescue JSON::ParserError => error
    failures << "invalid JSON-LD block #{index + 1}: #{error.message}"
  end

  failures.each { |failure| errors << "#{relative_path}: #{failure}" }
end

{
  "index.html" => %w[WebSite Organization SoftwareSourceCode ItemList],
  "docs/publications/index.html" => %w[ItemList]
}.each do |relative_path, required_types|
  path = site.join(relative_path)
  next errors << "missing SEO target: #{relative_path}" unless path.file?

  document = Nokogiri::HTML(path.read)
  types = document.css('script[type="application/ld+json"]').flat_map do |script|
    schema_types(JSON.parse(script.text))
  rescue JSON::ParserError
    []
  end
  missing_types = required_types - types
  errors << "#{relative_path}: missing schema types #{missing_types.join(', ')}" unless missing_types.empty?
end

robots = site.join("robots.txt")
sitemap = site.join("sitemap.xml")
errors << "missing robots.txt" unless robots.file?
errors << "missing sitemap.xml" unless sitemap.file?
if robots.file? && !robots.read.include?("Sitemap: #{expected_origin}/sitemap.xml")
  errors << "robots.txt does not advertise the production sitemap"
end
if sitemap.file? && !sitemap.read.include?("<loc>#{expected_origin}/")
  errors << "sitemap.xml does not use the production origin"
end

rendered_text = pages.map(&:read).join("\n")
errors << "rendered site contains the retired ESnet SENSE URL" if rendered_text.include?("/research-and-initiatives/sense/")
errors << "rendered site contains the retired SENSE Orchestrator URL" if rendered_text.include?("https://sense-o.es.net")

abort errors.join("\n") unless errors.empty?

puts "Validated SEO metadata and structured data in #{pages.length} rendered HTML pages."
puts "Validated canonical robots and sitemap output."
