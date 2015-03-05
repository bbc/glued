# encoding: utf-8

# Create glue with a manifest it recognises and it'll download the media
# file to the local directory.
#
@url
class Glue
  def initialize(url)
    @url = url
    
    fail "Invalid manifest url '#{url}' (it should end with .f4m)" unless url.to_s =~ /\.f4m$/ # Only by convention

    # xml = Curl::Easy.perform(url).body
    c = Curl::Easy.new(url)
    c.ssl_verify_peer = false
    c.headers["X-AUTH-MD-RADIX0"] = HEADER_AUTH
    c.perform
    @xml = c.body
    # @manifest = F4M.new(url, xml, nil)
    # @bootstrap = Bootstrap.new(@manifest.bootstrap_info)
  end
  
  
  def get_bitrates()
    xml = Nokogiri::XML(@xml)
    xml.remove_namespaces!
    list = xml.xpath('/manifest[1]/media')
    rates = []
    list.each do |media|
      br = media.at_css('@bitrate').value.to_i
      rates[br] = media
    end
    rates.reject { |e| e.nil? }
  end
  
  def grab(media)
    @manifest = F4M.new(@url, @xml, media)
    @bootstrap = Bootstrap.new(@manifest.bootstrap_info)
    Grabber.new(@manifest, @bootstrap)
  end
  
end
