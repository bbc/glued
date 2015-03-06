# encoding: utf-8

class Unstuck < Exception
end

# Grabs all the fragments that make up the media file and joins
# them within a local file.
#
class Grabber
  attr_reader :urls

  SANE_FRAGMENT_MAX = 10_000
  SANE_FRAGMENT_MIN = 1

  def initialize(manifest, bootstrap, io, do_download = true)
    # As we've hardcoded 1 into the @url below
    fail Unstuck, 'Only one segment can be handled' if bootstrap.segments != 1
    fail Unstuck, 'Not enough fragments' if bootstrap.fragments < SANE_FRAGMENT_MIN
    fail Unstuck, 'Too many fragments' if bootstrap.fragments > SANE_FRAGMENT_MAX

    @uri = "#{manifest.media_filename}.flv"
    @url = "#{manifest.base_ref}/#{manifest.media_filename}Seg1-Frag"
    @total_fragments = bootstrap.fragments
    @urls = []
    @downloaded_fragments = []
    @fragments_downloaded = 0
    @out = io

    create_download_file
    build
    download_all if do_download
  end

  private

  def create_download_file
    # TODO: Track how much has already been downloaded and append from that point
    # fail Unstuck, "Aborting as the download target file '#{@uri}' already exists" if File.exist? @uri
    if File.exist? @uri
      File.delete(@uri)
    end
    @out = File.new(@uri, 'ab') if @out.nil?

    # TODO: Test first fragment for audio and video write header accordingly
    @out.write(FLV.header)
  end

  def build
    # TODO, correctly set the fragment start
    fragment = 1
    while fragment <= @total_fragments
      @urls << "#{@url}#{fragment}"
      fragment += 1
    end
  end

  def download_all
    @urls.each do |url|
      
      download url 
    end
  
  end

  def download(url)
    file_name = url.split('/').pop

    dl = fetch_and_report(url)

    fail "Invalid content type '#{dl.content_type}' for fragment #{file_name}." unless dl.content_type == 'video/f4f'

    reader = F4VIO.new(dl.body)
    f4f = F4F.new(reader)

    # debug_stuff(dl.body)

    fail 'Fragment did not verify' unless f4f.ok?

    f4f.boxes.each do |box|
      if box.type == 'mdat'
        reader.pos = box.content_start
        data = reader.read(box.content_size)
        @out.write(data)
        
        # current_fragment = File.new("#{Time.now.to_f}.f4v", 'ab')
        # current_fragment.write(FLV.header)
        # current_fragment.write(data)
      end
    end

    @fragments_downloaded += 1
  end

  def fetch_and_report(url)
    start_time = Time.now


    c = Curl::Easy.new(url)
    c.ssl_verify_peer = false
    c.headers["X-AUTH-MD-RADIX0"] = HEADER_AUTH
    c.perform
    dl = c

    # dl = Curl::Easy.perform(url)

    report(dl.body.length, Time.now - start_time)

    dl
  end

  def report(number_of_bytes, in_seconds)
    bps = (number_of_bytes * 8) / in_seconds
    mbps = bps / 1_000_000

    print "\rDownloading #{@fragments_downloaded + 1}/#{@total_fragments} at #{mbps.round(2)} Mbps"
  end
end
