require 'socket'
require 'uri'

WEB_ROOT = '.'

CONTENT_TYPES = {
  'html': 'text/html',
  'txt': 'text/plain',
  'png': 'image/png',
  'jpg': 'image/jpeg'
}

DEFAULT_CONTENT_TYPE = 'application/octet-stream'


def content_type(path)
  ext = File.extname(path).split(".").last
  # Map to the file type or get the default one
  CONTENT_TYPES.fetch(ext, DEFAULT_CONTENT_TYPE)
end

def requested_file(request_line)
  requeset_uri = request_line.split(' ')[1]
  path = URI.unescape(URI(requeset_uri).path)
  clean = []

  parts = path.split('/')

  parts.each do |part|
    next if part.empty? || part  == '.'
    part == '..' ? clean.pop : clean << part
  end

  File.join(WEB_ROOT, *clean)
end

def response_header(file)
  "HTTP/1.1 200 OK\r\n" +
  "Content-Type: #{content_type(file)}\r\n" +
  "Content_Length: #{file.size}\r\n" +
  "Connection: close\r\n"
end

def response_404(message)
  "HTTP/1.1 404 Not Found\r\n" +
  "Content-Type: text/plain\r\n" +
  "Content-Length: #{message.size}\r\n" +
  "Connection: close\r\n"
end

server = TCPServer.new('localhost', 2345)

loop do
  socket = server .accept
  request_line = socket.gets

  STDERR.puts request_line
  path = requested_file(request_line)

  path = File.join(path, 'index.html') if File.directory?(path)

  if File.exist?(path) && !File.directory?(path)
    File.open(path, "rb") do |file|
      socket.print(response_header(file))
      socket.print "\r\n"

      IO.copy_stream(file, socket)
    end
  else
    message = "File not found\n"
    socket.print(response_404(message))
    socket.print "\r\n"
    socket.print message
  end
  socket.close
end
