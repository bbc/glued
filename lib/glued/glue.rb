# encoding: utf-8

# Create glue with a manifest it recognises and it'll download the media
# file to the local directory.
#
@url
@bootstrap
class Glue
  def initialize(url)
    @url = url
    @bootstrap = nil
    fail "Invalid manifest url '#{url}' (it should end with .f4m)" unless url.to_s =~ /\.f4m$/ # Only by convention

    # xml = Curl::Easy.perform(url).body
    c = Curl::Easy.new(url)
    c.ssl_verify_peer = false
    c.headers["X-AUTH-MD-RADIX0"] = HEADER_AUTH
    c.perform
    @xml = c.body
  end
  
  def get_segment_duration(media)
    @manifest = F4M.new(@url, @xml, media, false)
    @bootstrap = Bootstrap.new(@manifest.bootstrap_info)
    ((@bootstrap.boxes.first.fragment_run_tables.first.run_entry_table.first.fragment_duration).to_f/(@bootstrap.boxes.first.time_scale).to_f)
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
  
  def get_total_segments(media)
    @manifest = F4M.new(@url, @xml, media, true)
    @bootstrap = Bootstrap.new(@manifest.bootstrap_info)
    @bootstrap.fragments
  end
  
  def get_all_media(media, destination)
    # add destination
    @manifest = F4M.new(@url, @xml, media)
    @bootstrap = Bootstrap.new(@manifest.bootstrap_info)
    io = File.new(destination, 'ab')
    Grabber.new(@manifest, @bootstrap, io)
  end
  
end
