# takes Pagination Link headers generated for Webservices
# and converts them into links for External API

class PaginationLinkBuilder

    def initialize header_str, current_url
      @header_str, @current_url = header_str, current_url
      @rel_hash   = {}
    end

    def build_rel_hash
      @header_str.split(', ').each do |line|
        sections = line.split('; ')
        incoming_url = sections[0][1..-2]
        page = UrlHandler.new(incoming_url).query_params['page']
        rel = sections[1].split("rel=")[1][1..-2]

        url_with_page = UrlHandler.new(@current_url)
        url_with_page.query_params['page'] = page

        @rel_hash[rel] = url_with_page.to_s
      end
    end

    def to_s
      build_rel_hash
      output =  ""
      output << "<#{@rel_hash['first']}>; rel=\"first\", " if @rel_hash['first']
      output << "<#{@rel_hash['prev']}>; rel=\"prev\", "   if @rel_hash['prev']
      output << "<#{@rel_hash['last']}>; rel=\"last\", "   if @rel_hash['last']
      output << "<#{@rel_hash['next']}>; rel=\"next\", "   if @rel_hash['next']
      output
    end

end
