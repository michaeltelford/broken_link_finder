require 'webmock'

include WebMock::API
WebMock.enable!

$mock_server        = "http://mock-server.com/"
$mock_external_site = "https://some-external-site.com.au"
$mock_invalid_url   = "https://doesnt-exist.com"
$mock_invalid_link  = "not_found"

def mock_response(file_name, status: 200)
  file_path = "test/fixtures/#{file_name}.html"
  { status: status, body: File.read(file_path) }
end

# / (index webpage for $mock_server)
stub_request(:get, $mock_server).
  to_return(mock_response('index'))

# /contact
stub_request(:get, $mock_server + 'contact').
  to_return(mock_response('contact'))

# /about
stub_request(:get, $mock_server + 'about').
  to_return(mock_response('about'))

# /location
stub_request(:get, $mock_server + 'location').
  to_return(mock_response('location'))

# / (index page for $mock_external_site)
stub_request(:get, $mock_external_site).
  to_return(mock_response('mock_external_site'))

# Invalid external URL
stub_request(:get, $mock_invalid_url).
  to_return(status: 404)

# Invalid internal link
stub_request(:get, $mock_server + $mock_invalid_link).
  to_return(status: 404)
