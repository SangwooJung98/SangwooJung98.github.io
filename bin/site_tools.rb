require 'cgi'
require 'digest'
require 'json'
require 'nokogiri'
require 'pathname'
require 'uri'

module SiteTools
  # Resolve a site's own URL to a build artifact; external URLs are checked separately.
  def self.local_file(destination, page, reference, site_url, baseurl = '')
    return if reference.nil? || reference.empty? || reference.start_with?('#', 'data:', 'mailto:', 'tel:', 'javascript:')

    uri = URI.parse(reference.gsub(' ', '%20'))
    return if uri.host && uri.host.downcase != URI(site_url).host.downcase
    return if uri.scheme && !%w[http https].include?(uri.scheme)

    path = URI::DEFAULT_PARSER.unescape(uri.path.to_s)
    path = path.delete_prefix(baseurl) if !baseurl.empty? && (path == baseurl || path.start_with?(baseurl + '/'))
    relative = if path.start_with?('/') || uri.host
                 path.sub(%r{\A/+}, '')
               elsif path.empty?
                 page
               else
                 File.join(File.dirname(page), path)
               end
    target = File.expand_path(relative, destination)
    root = File.expand_path(destination)
    raise ArgumentError, "URL escapes the site: #{reference}" unless target == root || target.start_with?(root + '/')

    target = File.join(target, 'index.html') if File.directory?(target) || path.end_with?('/') || path.empty? && uri.host
    target
  end

  # Run after PurgeCSS so the URL represents the bytes that will actually be deployed.
  def self.fingerprint_css(destination, site_url, baseurl = '')
    Dir.glob(File.join(destination, '**/*.html')).each do |page|
      relative = Pathname(page).relative_path_from(Pathname(destination)).to_s
      html = File.read(page)
      updated = html.gsub(/\bhref=(['"])([^'"]+\.css(?:\?[^'"]*)?)\1/) do |attribute|
        quote, reference = Regexp.last_match.captures
        reference = CGI.unescapeHTML(reference)
        target = local_file(destination, relative, reference, site_url, baseurl)
        next attribute unless target
        raise "Missing stylesheet: #{reference} in #{relative}" unless File.file?(target)

        version = Digest::SHA256.file(target).hexdigest[0, 16]
        "href=#{quote}#{CGI.escapeHTML(reference.split('?').first)}?v=#{version}#{quote}"
      end
      File.write(page, updated) if updated != html
    end
  end

  def self.main_text(document)
    main = document.at_css('[role="main"]').dup
    main.css('div.bibtex, script').remove
    main.xpath('.//text()').map(&:text).join(' ').gsub(/[[:space:]]+/, ' ').strip
  end

  def self.verify(destination, site_url:, baseurl: '', fixture:)
    errors = []
    html_files = Dir.glob(File.join(destination, '**/*.html')).sort
    expected_pages = %w[404.html cv/index.html index.html publications/index.html]
    relative_pages = html_files.map { |p| Pathname(p).relative_path_from(Pathname(destination)).to_s }
    errors << "Unexpected public pages: #{relative_pages - expected_pages}" unless (relative_pages - expected_pages).empty?
    errors << "Missing public pages: #{expected_pages - relative_pages}" unless (expected_pages - relative_pages).empty?

    html_files.each do |file|
      relative = Pathname(file).relative_path_from(Pathname(destination)).to_s
      doc = Nokogiri::HTML(File.read(file))
      references = doc.css('[href], [src]').flat_map { |node| %w[href src].filter_map { |attr| node[attr] } }
      references.concat(doc.css('[srcset]').flat_map { |node| node['srcset'].split(',').map { |part| part.strip.split.first } })
      references.compact.uniq.each do |reference|
        begin
          target = local_file(destination, relative, reference, site_url, baseurl)
          errors << "#{relative}: missing #{reference}" if target && !File.file?(target)
        rescue URI::InvalidURIError, ArgumentError => error
          errors << "#{relative}: #{error.message}"
        end
      end
      doc.css('link[rel="stylesheet"]').each do |node|
        target = local_file(destination, relative, node['href'], site_url, baseurl)
        next unless target && File.file?(target)
        version = Digest::SHA256.file(target).hexdigest[0, 16]
        errors << "#{relative}: stale CSS version #{node['href']}" unless node['href'].end_with?("?v=#{version}")
      end
      path = '/' + relative.sub(/index\.html\z/, '')
      canonical = site_url.sub(%r{/+\z}, '') + baseurl + path
      errors << "#{relative}: incorrect canonical URL" unless doc.at_css('link[rel="canonical"]')&.[]('href') == canonical
      next unless fixture['pages'].key?(relative)

      baseline = fixture['pages'][relative]
      errors << "#{relative}: published main content changed" unless main_text(doc) == baseline['text']
      ids = doc.css('.publications .row > div[id]').map { |node| node['id'] }
      errors << "#{relative}: publication order changed" unless ids == baseline['publication_ids']
    end

    Dir.glob(File.join(destination, 'assets/css/*.css')).each do |file|
      relative = Pathname(file).relative_path_from(Pathname(destination)).to_s
      File.read(file).scan(/url\(\s*['"]?([^)'"\s]+)['"]?\s*\)/).flatten.uniq.each do |reference|
        target = local_file(destination, relative, reference, site_url, baseurl)
        errors << "#{relative}: missing #{reference}" if target && !File.file?(target)
      end
    end
    # Selected entries and the full list must expose the same citation after edits.
    home_file = File.join(destination, 'index.html')
    publications_file = File.join(destination, 'publications/index.html')
    if File.file?(home_file) && File.file?(publications_file)
      home = Nokogiri::HTML(File.read(home_file))
      publications = Nokogiri::HTML(File.read(publications_file))
      home.css('.publications .row > div[id]').each do |entry|
        citation = entry.at_css('.bibtex code')&.text
        next unless citation

        counterpart = publications.at_xpath("//*[@id=#{entry['id'].inspect}]")
        other_citation = counterpart&.at_css('.bibtex code')&.text
        errors << "Inconsistent selected citation: #{entry['id']}" unless citation == other_citation
      end
    end

    fixture['pdf_sha256'].each do |path, digest|
      file = File.join(destination, path)
      errors << "Missing or changed PDF: #{path}" unless File.file?(file) && Digest::SHA256.file(file).hexdigest == digest
    end
    sitemap_file = File.join(destination, 'sitemap.xml')
    if File.file?(sitemap_file)
      sitemap = Nokogiri::XML(File.read(sitemap_file))
      sitemap.remove_namespaces!
      locations = sitemap.css('loc').map(&:text)
      wanted = %w[/ /cv/ /publications/].map { |p| site_url.sub(%r{/+\z}, '') + baseurl + p }
      errors << 'Sitemap must contain only the three public content pages' unless locations.sort == wanted.sort
    else
      errors << 'Missing sitemap.xml'
    end
    errors << 'Demo RSS feed remains' if File.exist?(File.join(destination, 'feed.xml'))
    errors
  end
end
