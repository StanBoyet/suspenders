require 'spec_helper'

feature 'Suspend a new project with default configuration' do
  scenario 'specs pass' do
    run_suspenders

    Dir.chdir(project_path) do
      Bundler.with_clean_env do
        expect(`rake`).to include('0 failures')
      end
    end
  end

  scenario 'staging config is inherited from production' do
    run_suspenders

    staging_file = IO.read("#{project_path}/config/environments/staging.rb")
    config_stub = "Rails.application.configure do"
    expect(staging_file).to match(/^require_relative 'production'/)
    expect(staging_file).to match(/#{config_stub}/), staging_file
  end

  if RUBY_VERSION >= '2.1.0'
    scenario '.ruby-version does not include patchlevel for Ruby 2.1.0+' do
      run_suspenders

      ruby_version_file = IO.read("#{project_path}/.ruby-version")
      expect(ruby_version_file).to eq "#{RUBY_VERSION}\n"
    end
  else
    scenario '.ruby-version includes patchlevel for all pre-Ruby 2.1.0 versions' do
      run_suspenders

      ruby_version_file = IO.read("#{project_path}/.ruby-version")
      expect(ruby_version_file).to eq "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}\n"
    end
  end

  scenario 'records pageviews through Segment.io if ENV variable set' do
    run_suspenders

    expect(analytics_partial).
      to include("<% if ENV['SEGMENT_IO_KEY'] %>")
    expect(analytics_partial).
      to include("window.analytics.load('<%= ENV['SEGMENT_IO_KEY'] %>');")
  end

  def analytics_partial
    IO.read("#{project_path}/app/views/application/_analytics.html.erb")
  end
end
