require 'webmock'

include WebMock::API

WebMock.enable!
WebMock.disable_net_connect!

def mock_response(file_name, status: 200)
  file_name += '.html' unless file_name.include?('.')
  file_path = "test/fixtures/#{file_name}"
  { status: status, body: File.read(file_path) }
end

# / (index webpage for the mock server)
stub_request(:get, 'http://mock-server.com/')
  .to_return(mock_response('index'))

# /contact
stub_request(:get, 'http://mock-server.com/contact')
  .to_return(mock_response('contact'))
stub_request(:get, 'http://mock-server.com/contact#help')
  .to_return(mock_response('contact'))
stub_request(:get, "http://mock-server.com/contact#doesntexist")
  .to_return(mock_response('contact'))

# /about
stub_request(:get, 'http://mock-server.com/about')
  .to_return(mock_response('about'))
stub_request(:get, 'http://mock-server.com/about?q=world')
  .to_return(mock_response('about'))

# /location
stub_request(:get, 'http://mock-server.com/location')
  .to_return(mock_response('location'))
stub_request(:get, 'http://mock-server.com/location?q=hello')
  .to_return(mock_response('location'))

# Mock external site
stub_request(:get, 'https://some-external-site.com.au')
  .to_return(mock_response('mock_external_site'))

# JS and CSS links (to check they aren't crawled)
stub_request(:get, 'http://mock-server.com/script.js')
  .to_return(mock_response('script.js'))
stub_request(:get, 'http://mock-server.com/styles.css')
  .to_return(mock_response('styles.css'))

# Invalid external URL
stub_request(:get, 'https://doesnt-exist.com')
  .to_return(mock_response('not_found', status: 404))

# Invalid internal link
stub_request(:get, 'http://mock-server.com/not_found')
  .to_return(mock_response('not_found', status: 404))

# Redirect - Absolute Location
stub_request(:get, 'http://mock-server.com/redirect')
  .to_return(status: 301, headers: { 'Location': 'http://mock-server.com/location' })

# Redirect - Relative Location
stub_request(:get, 'http://mock-server.com/redirect/2')
  .to_return(status: 301, headers: { 'Location': '/location' })

# Broken external redirect
stub_request(:get, 'http://broken.external.redirect.test.com')
  .to_return(status: 200, body:
    '<a href="http://broken.external.redirect.com">Broken External Redirect</a>'
  )
stub_request(:get, 'http://broken.external.redirect.com')
  .to_return(status: 301, headers: { 'Location': 'https://server-error.com' })

# Server error
stub_request(:get, 'https://server-error.com')
  .to_return(status: 500)

# example.co.uk aka fixtures/links.html
stub_request(:get, 'https://example.co.uk/links.html')
  .to_return(mock_response('links'))
stub_request(:get, 'https://example.co.uk/links.html#anchorthatdoesnotexist')
  .to_return(mock_response('links'))
stub_request(:get, 'https://example.com')
  .to_return(mock_response('index'))
stub_request(:get, 'https://example.com/')
  .to_return(mock_response('index'))
stub_request(:get, 'https://example.com#anchorthandoesnotexist')
  .to_return(mock_response('index'))

# broken links from fixtures/links.html
[
  'https://example.co.uk/images/non-existing_logo.png',
  'https://example.co.uk/nonexisting_page.html',
  'https://example.co.uk/nonexisting_page.html#anchorthatdoesnotexist',

  'https://example.co.uk/images/non-existent_logo.png',
  'https://example.co.uk/nonexistent_page.html',
  'https://example.co.uk/nonexistent_page.html#anchorthatdoesnotexist',

  'https://example.com/images/non-existing_logo.png',
  'https://example.com/brokenlink',
  'https://example.com/brokenlink#anchorthandoesnotexist',

  'https://thisdomaindoesnotexist-thouthou.com/badpage.html',
  'https://thisdomaindoesnotexist-thouthou.com/nonexistentimage.png',
  'https://thisdomaindoesnotexist-thouthou.com/badpage.html#anchorthatdoesnotexist'
].each do |url|
  stub_request(:get, url).to_return(mock_response('not_found', status: 404))
end

# Stubs for testing Finder's retry mechanism.
stub_request(:get, 'http://www.retry.com')
  .to_return(mock_response('retry'))
stub_request(:get, 'http://dos-preventer.net')
  .to_timeout.then
  .to_return(mock_response('index')).then
  .to_timeout.then
  .to_return(mock_response('index'))
