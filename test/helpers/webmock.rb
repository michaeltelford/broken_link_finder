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
  to_return(mock_response('not_found', status: 404))

# Invalid internal link
stub_request(:get, 'http://mock-server.com/not_found').
  to_return(mock_response('not_found', status: 404))

# Redirect - Absolute Location
stub_request(:get, 'http://mock-server.com/redirect').
  to_return(status: 301, headers: { 'Location': 'http://mock-server.com/location' })

# Redirect - Relative Location
stub_request(:get, 'http://mock-server.com/redirect/2').
  to_return(status: 301, headers: { 'Location': '/location' })

# Server error
stub_request(:get, 'https://server-error.com').
  to_return(status: 500)

# meosch.tk aka fixtures/links.html
stub_request(:get, 'https://meosch.tk/links.html').
  to_return(mock_response('links'))
stub_request(:get, 'https://meos.ch').
  to_return(mock_response('index'))
stub_request(:get, 'https://meos.ch/').
  to_return(mock_response('index'))
stub_request(:get, 'https://meos.ch#anchorthandoesnotexist').
  to_return(mock_response('index'))

# broken links from fixtures/links.html
[
  'https://meosch.tk/images/non-existing_logo.png',
  'https://meosch.tk/nonexisting_page.html',
  'https://meosch.tk/nonexisting_page.html#anchorthatdoesnotexist',

  'https://meosch.tk/images/non-existent_logo.png',
  'https://meosch.tk/nonexistent_page.html',
  'https://meosch.tk/nonexistent_page.html#anchorthatdoesnotexist',

  'https://meos.ch/images/non-existing_logo.png',
  'https://meos.ch/brokenlink',
  'https://meos.ch/brokenlink#anchorthandoesnotexist',

  'https://thisdomaindoesnotexist-thouthou.com/badpage.html',
  'https://thisdomaindoesnotexist-thouthou.com/nonexistentimage.png',
  'https://thisdomaindoesnotexist-thouthou.com/badpage.html#anchorthatdoesnotexist',
].each do |url|
  stub_request(:get, url).to_return(mock_response('not_found', status: 404))
end
