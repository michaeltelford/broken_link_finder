require 'webmock'

include WebMock::API
WebMock.enable!

def mock_response(file_name, status: 200)
  file_path = "test/fixtures/#{file_name}.html"
  { status: status, body: File.read(file_path) }
end

# / (index webpage for $mock_server)
stub_request(:get, 'http://mock-server.com/').
  to_return(mock_response('index'))

# /contact
stub_request(:get, 'http://mock-server.com/contact').
  to_return(mock_response('contact'))

# /about
stub_request(:get, 'http://mock-server.com/about').
  to_return(mock_response('about'))

# /location
stub_request(:get, 'http://mock-server.com/location').
  to_return(mock_response('location'))

# / (index page for $mock_external_site)
stub_request(:get, 'https://some-external-site.com.au').
  to_return(mock_response('mock_external_site'))

# Invalid external URL
stub_request(:get, 'https://doesnt-exist.com').
  to_return(status: 404)

# Invalid internal link
stub_request(:get, 'http://mock-server.com/not_found').
  to_return(status: 404)

# Redirect - Absolute Location
stub_request(:get, 'http://mock-server.com/redirect').
  to_return(status: 301, headers: { 'Location': 'http://mock-server.com/location' })

# Redirect - Relative Location
stub_request(:get, 'http://mock-server.com/redirect/2').
  to_return(status: 301, headers: { 'Location': '/location' })
