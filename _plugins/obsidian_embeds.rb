module ObsidianEmbeds
  IMAGE_EXTS = %w[.png .jpg .jpeg .gif .webp .svg .avif .bmp].freeze
  SEARCH_DIRS = %w[assets].freeze

  # rel paths (repo-relative) of every image under SEARCH_DIRS
  def self.build_index(site)
    paths = []
    SEARCH_DIRS.each do |dir|
      Dir.glob(File.join(site.source, dir, "**", "*")).each do |abs|
        next unless File.file?(abs)
        next unless IMAGE_EXTS.include?(File.extname(abs).downcase)
        paths << abs.sub(/\A#{Regexp.escape(site.source)}\/?/, "")
      end
    end
    paths
  end

  def self.resolve(target, index)
    t = target.downcase.gsub('\\', '/').sub(%r{\A/}, '')

    # exact or partial path match wins ("notes/foo.png")
    hit = index.find { |p| p.downcase == t || p.downcase.end_with?("/#{t}") }
    return hit if hit

    # otherwise match on filename alone
    base = File.basename(t)
    matches = index.select { |p| File.basename(p).downcase == base }

    if matches.length > 1
      Jekyll.logger.warn "Obsidian:", "ambiguous embed '#{target}' -> #{matches.join(', ')}"
    end
    matches.first
  end

  def self.encode(rel)
    "/" + rel.split("/").map { |s| ERB::Util.url_encode(s) }.join("/")
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  site.data["_obsidian_images"] = ObsidianEmbeds.build_index(site)
end

Jekyll::Hooks.register [:posts, :pages], :pre_render do |doc|
  index = doc.site.data["_obsidian_images"] || []

  doc.content = doc.content.gsub(/!\[\[([^\]|]+?)(?:\|([^\]]*))?\]\]/) do
    target = Regexp.last_match(1).strip
    opt    = Regexp.last_match(2)&.strip
    rel    = ObsidianEmbeds.resolve(target, index)

    if rel.nil?
      Jekyll.logger.warn "Obsidian:", "no image found for '#{target}' in #{doc.relative_path}"
      next "<!-- missing image: #{target} -->"
    end

    src = ObsidianEmbeds.encode(rel)
    alt = (opt && !opt.empty? && opt !~ /\A\d+(x\d+)?\z/) ? opt : File.basename(target, ".*")

    if opt =~ /\A(\d+)(?:x(\d+))?\z/
      w, h = Regexp.last_match(1), Regexp.last_match(2)
      %(<img src="#{src}" alt="#{alt}" width="#{w}"#{h ? %( height="#{h}") : ''} />)
    else
      "![#{alt}](#{src})"
    end
  end
end
