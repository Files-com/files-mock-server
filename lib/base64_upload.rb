class Base64Upload
  attr_reader :tempfile, :filename

  def initialize(file_content, filename, _filetype)
    @tempfile = StringIO.new(file_content)
    @filename = filename.present? ? filename : "file.ext"
  end
end
