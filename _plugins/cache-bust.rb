require 'digest'

module Jekyll
  module CacheBust
    def bust_file_cache(file_name)
      site = @context.registers[:site]
      relative = file_name.split('?', 2).first.sub(%r{\A#{Regexp.escape(site.baseurl)}/?}, '')
      path = site.in_source_dir(relative)
      raise Jekyll::Errors::FatalException, "Missing cache-busted asset: #{relative}" unless File.file?(path)

      "#{file_name}?v=#{Digest::SHA256.file(path).hexdigest[0, 16]}"
    end
  end
end

Liquid::Template.register_filter(Jekyll::CacheBust)
