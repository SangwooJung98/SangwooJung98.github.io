require 'jekyll/scholar'

# Use the same entries as /publications/, preserving the explicit homepage order.
class SelectedBibliographyTag < Jekyll::Scholar::BibliographyTag
  def entries
    keys = site.data.fetch('selected_papers')
    raise Jekyll::Errors::FatalException, 'Duplicate selected paper keys' unless keys.uniq == keys

    keys.map do |key|
      bibliography[key] || raise(Jekyll::Errors::FatalException, "Unknown selected paper: #{key}")
    end
  end
end

Liquid::Template.register_tag('selected_bibliography', SelectedBibliographyTag)
