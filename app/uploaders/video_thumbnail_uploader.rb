# encoding: utf-8

class VideoThumbnailUploader < BaseUploader
  version :snapshot do
    process :take_snapshot

    def full_filename(for_file)
      jpg_name(for_file, version_name)
    end
  end

  def jpg_name(for_file, version_name, offset = model.offset)
    base = "#{for_file.chomp(File.extname(for_file))}"
    base += "_#{offset}" if offset
    "#{base}.jpg"
  end

  def take_snapshot
    offset = model.offset
    movie = FFMPEG::Movie.new(current_path)
    movie.screenshot(current_path, seek_time: offset)
  end
end
