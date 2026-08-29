Jekyll::Hooks.register [:posts, :pages], :pre_render do |doc|
  doc.content = doc.content.gsub(/!\[\[([^\]|]+?)(?:\|([^\]]*))?\]\]/) do
    file = Regexp.last_match(1).strip
    opt  = Regexp.last_match(2)&.strip
    src  = "/assets/images/#{file.gsub(' ', '%20')}"

    if opt =~ /\A(\d+)(?:x(\d+))?\z/
      w, h = Regexp.last_match(1), Regexp.last_match(2)
      %(<img src="#{src}" alt="#{file}" width="#{w}"#{h ? %( height="#{h}") : ''} />)
    else
      "![#{opt && !opt.empty? ? opt : file}](#{src})"
    end
  end
end
