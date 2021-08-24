require 'id3tag'

class Mp3Organizer
  attr_reader :target_path, :temp_dir_path

  def initialize(target_path)
    @target_path = target_path
    @temp_dir_path = "#{target_path}/temp-#{Time.now.to_i}"
  end

  def perform!
    raise 'Must provide a directory path' and return if !target_path || target_path.empty?

    create_temp_dir

    mp3_filenames.each do |filename| 
      mp3_file = Mp3File.new(target_path, filename)

      puts mp3_file.to_s 

      mp3_file.copy_to(create_artist_album_directory(mp3_file.metadata[:artist], mp3_file.metadata[:album]))

      mp3_file.close
    end
  end

  private
     def create_temp_dir
       Dir.mkdir(temp_dir_path)      
     end 

     def mp3_filenames
       return Dir.entries(target_path).select { |filename| filename.match?(/\.mp3/) }
     end

    def create_artist_album_directory(artist, album)
      artist_album_path = "#{temp_dir_path}/#{artist} - #{album}"
      Dir.mkdir(artist_album_path) unless Dir.exist?(artist_album_path)

      return artist_album_path
     end

  class Mp3File
    attr_reader :file, :tags, :file_name

    def initialize(target_path, file_name)
      @file_name = file_name
      @file = File.open("#{target_path}/#{file_name}", "rb")
      @tags = ID3Tag.read(@file)
    end

    def metadata
      return {
        filename: file_name,
        artist: (tags.artist && !tags.artist.empty?) ? tags.artist.gsub(/\W/, ' ') : 'Unknown',
        album: (tags.album && !tags.album.empty?) ? tags.album.gsub(/\W/, ' ') : 'Unknown'
      }
    end

    def copy_to(path)
      FileUtils.cp(file.path, path)
    end

    def close
      file.close
    end

    def to_s
      return "#{metadata[:filename]}\n"\
             "#{metadata[:artist]}\n"\
             "#{metadata[:album]}\n"\
             "---"
    end
  end
end

Mp3Organizer.new(ARGV[0]).perform!

