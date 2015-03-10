# encoding: utf-8

# Deserialises the manifest
#
class F4M
  NAMESPACE = 'http://ns.adobe.com/f4m/'
  @xml
  attr_reader :duration,
  :bootstrap_info,
  :base_ref,
  :media_filename,
  :media

  def initialize(url, data, media)
    @xml = Nokogiri::XML(data)

    namespace = @xml.root.namespace.href rescue 'not found'
    fail "Invalid manifest namespace. It was #{namespace} but should have been #{NAMESPACE}" unless namespace.include?(NAMESPACE)

    @xml.remove_namespaces!

    # stream_type = @xml.xpath('//streamType').first.text rescue 'unknown'
    # fail 'Only recorded streams are supported.' unless stream_type == 'recorded'

    @duration = @xml.xpath('//duration').first.text.to_i

    b64_bootstrap_info = @xml.xpath('//bootstrapInfo').first.text
    @bootstrap_info = Base64.strict_decode64(b64_bootstrap_info)

    media_nodes = @xml.xpath('/manifest[1]/media')
    # @media = find_bitrates(media_nodes).sample
    if(media.nil?)
      media = find_highest_bitrate(media_nodes)
    end
    @media_filename = media.at_css('@url').value

    @base_ref = url.split('/').slice(0...-1).join('/') # can be specified in @xml
  end


  def find_highest_bitrate(list)
    rates = []
    list.each do |media|
      br = media.at_css('@bitrate').value.to_i
      rates[br] = media
    end
    rates.reject { |e| e.nil? }.pop
  end
end
