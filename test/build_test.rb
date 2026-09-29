require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../bin/site_tools'

class BuildTest < Minitest::Test
  SITE_URL = 'https://sangwoojung98.github.io'.freeze

  def setup
    @site = Dir.mktmpdir('homepage-test')
    FileUtils.mkdir_p(File.join(@site, 'assets/css'))
    @css = File.join(@site, 'assets/css/main.css')
    File.write(@css, 'body{color:red}')
    @page = File.join(@site, 'index.html')
    File.write(@page, '<link rel="stylesheet" href="/assets/css/main.css?old"><link href="https://example.com/other.css">')
  end

  def teardown
    FileUtils.remove_entry(@site)
  end

  def test_css_version_tracks_final_bytes_and_is_idempotent
    SiteTools.fingerprint_css(@site, SITE_URL)
    first = File.read(@page)
    assert_includes first, Digest::SHA256.file(@css).hexdigest[0, 16]
    assert_includes first, 'https://example.com/other.css'
    SiteTools.fingerprint_css(@site, SITE_URL)
    assert_equal first, File.read(@page)
    File.write(@css, 'body{color:blue}')
    SiteTools.fingerprint_css(@site, SITE_URL)
    refute_equal first, File.read(@page)
    assert_includes File.read(@page), Digest::SHA256.file(@css).hexdigest[0, 16]
  end

  def test_missing_stylesheet_blocks_finalization
    File.unlink(@css)
    assert_raises(RuntimeError) { SiteTools.fingerprint_css(@site, SITE_URL) }
  end

  def test_local_references_include_absolute_pdf_and_responsive_images
    assert_equal File.join(@site, 'pdf/paper.pdf'), SiteTools.local_file(@site, 'publications/index.html', "#{SITE_URL}/pdf/paper.pdf", SITE_URL)
    assert_equal File.join(@site, 'assets/img/profile-480.webp'), SiteTools.local_file(@site, 'cv/index.html', '../assets/img/profile-480.webp', SITE_URL)
    assert_equal @css, SiteTools.local_file(@site, 'index.html', '/preview/assets/css/main.css?v=abc', SITE_URL, '/preview')
    assert_nil SiteTools.local_file(@site, 'index.html', 'https://example.com/page', SITE_URL)
    assert_raises(ArgumentError) { SiteTools.local_file(@site, 'index.html', '../../secret', SITE_URL) }
  end

  def test_missing_srcset_member_is_a_failure
    File.write(@page, '<div role="main">Example</div><source srcset="/missing-480.webp 480w, /missing-800.webp 800w">')
    errors = SiteTools.verify(@site, site_url: SITE_URL, fixture: { 'pages' => {}, 'pdf_sha256' => {} })
    assert_includes errors, 'index.html: missing /missing-480.webp'
    assert_includes errors, 'index.html: missing /missing-800.webp'
  end
end
