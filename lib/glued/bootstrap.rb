# encoding: utf-8

# Bootstrap decoder.
#
# The boostrap files describe the segments and fragments that form
# the media file.
#
class Bootstrap
  attr_reader :boxes

  def initialize(data)
    @reader = F4VIO.new(data)
    @boxes = []
    scan
  end

  # Top level
  AFRA = 'afra' # Fragment random access for HTTP streaming
  ABST = 'abst' # Bootstrap info for HTTP streaming
  MOOV = 'moov' # Container for structural metadata
  MOOF = 'moof' # Movie Fragment
  MDAT = 'mdat' # Moovie data container

  # Inside ABST
  ASRT = 'asrt' # Segment run table box
  AFRT = 'afrt' # Fragment runt table box

  def segments
    @boxes.first.segments
  end

  def fragments
    @boxes.first.segment_run_tables.first.run_entry_table.first.fragments_per_segment
  end

  private

  def scan
    
    # Scan for 'boxes' in the stream see spec 1.3 F4V box format
    until @reader.eof?
      box = make_box_header

      case box.type
      when ABST
        @boxes << make_bootstrap_box(box)
      when AFRA
        @boxes << box
      when MDAT
        @boxes << box
      else
        break
      end
    end

    fail 'Computer says no' if @boxes.empty?

    @boxes
  end

  def make_box_header
    pos = @reader.pos
    size = @reader.int32
    type = @reader.four_cc

    # For boxes over 4GB the size is moved after the type
    size = @reader.int64 if size == 1

    Header.new(pos, size, type)
  end

  def make_bootstrap_box(header)
    # 2.11.2 Bootstrap Info box
    b                        = BootstrapBox.new
    b.header                 = header
    b.version                = @reader.byte
    b.flags                  = @reader.int24
    b.bootstrap_info_version = @reader.int32

    plu                      = @reader.byte
    b.profile                = plu >> 6
    b.live                   = (plu & 0x20) ? 1 : 0
    b.update                 = (plu & 0x01) ? 1 : 0
    b.time_scale             = @reader.int32
        
    b.current_media_time     = @reader.int64
    b.smpte_timecode_offset  = @reader.int64
    b.movie_identifier       = @reader.string
    b.servers                = @reader.byte_ar
    b.quality                = @reader.byte_ar
    b.drm_data               = @reader.string
    b.metadata               = @reader.string
    b.segments               = @reader.byte
    b.segment_run_tables     = []
    b.segments.times { b.segment_run_tables << make_asrt_box(make_box_header) }

    fail 'There should be at least one segment entry' if b.segment_run_tables.empty?

    b.fragments               = @reader.byte
    b.fragment_run_tables     = []
    b.fragments.times { b.fragment_run_tables << make_afrt_box(make_box_header) }

    fail 'There should be at least one fragment entry' if b.fragment_run_tables.empty?

    b
  end

  def make_asrt_box(header)
    # 2.11.2.1 Segment Run Table box
    fail "Unexpected segment run table box header '#{header.type}' instead of '#{ASRT}'" unless header.type == ASRT

    b = RunTableBox.new
    b.header                        = header
    b.version                       = @reader.byte
    b.flags                         = @reader.int24
    b.quality_segment_url_modifiers = @reader.byte_ar

    table = []
    runs = @reader.int32

    runs.times do
      first_segment = @reader.int32
      fragments_per_segment = @reader.int32

      table << SegmentRunEntry.new(first_segment, fragments_per_segment)
    end

    b.run_entry_table = table
    b
  end

  def make_afrt_box(header)
    # 2.11.2.2 Fragment Run Table box
    fail "Unexpected fragment run table box header '#{header.type}' instead of '#{AFRT}'" unless header.type == AFRT

    b = RunTableBox.new
    b.header                        = header
    b.version                       = @reader.byte
    b.flags                         = @reader.int24
    b.time_scale                    = @reader.int32
    b.quality_segment_url_modifiers = @reader.byte_ar

    table = []
    runs = @reader.int32

    runs.times do
      f = FragmentRunEntry.new
      f.first_fragment = @reader.int32
      f.first_fragment_timestamp = @reader.int64
      f.fragment_duration = @reader.int32
      f.discontinuity_indicator = @reader.byte if f.fragment_duration == 0

      table << f
    end

    b.run_entry_table = table
    b
  end
end

class Header < Struct.new(:pos, :size, :type)
  # pos, starting position within the byte stream
  # size, number of bytes within the box
  # type, descriptive type for the bytes stored in the box
end

class BootstrapBox < Struct.new(:header,
                                :version,
                                :flags,
                                :bootstrap_info_version,
                                :profile,
                                :live,
                                :update,
                                :time_scale,
                                :current_media_time,
                                :smpte_timecode_offset,
                                :movie_identifier,
                                :servers,
                                :quality,
                                :drm_data,
                                :metadata,
                                :segments,
                                :segment_run_tables,
                                :fragments,
                                :fragment_run_tables)
end

class SegmentRunEntry < Struct.new(:first_segment, :fragments_per_segment)
end

class FragmentRunEntry < Struct.new(:first_fragment,
                                    :first_fragment_timestamp,
                                    :fragment_duration,
                                    :discontinuity_indicator)
end

# For Segment and Fragment boxes
class RunTableBox < Struct.new(:header,
                               :version,
                               :flags,
                               :time_scale,
                               :quality_segment_url_modifiers,
                               :run_entry_table)
end
