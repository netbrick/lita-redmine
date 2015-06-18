require 'resource_kit'
require 'faraday'
require 'json'

class RedmineResource < ResourceKit::Resource
  resources do
    default_handler (401) { |response| "Wrong API token, please register new one" }
    default_handler (404) { |response| "Server responded with error code 404, please check you have correct parameters" }
    default_handler (422) { |response| "Wrong parameters (#{response.body})" }
    default_handler { |response| "Unknown error, status: #{response.status}, body: #{response.body}" }

    action :list do
      verb :get
      path '/:object.json?limit=1000'
      handler (:ok) { |response| JSON.parse(response.body) }
    end

    action :create_entry do
      verb :post
      path '/time_entries.json'
      body { |object| { time_entry: object } }
      handler (:created) { |response| "Time entry created" }
    end

    action :users do
      verb :get
      path '/users.json?limit=1000'
      handler (:ok) { |response| JSON.parse(response.body)['users'] }
    end

    action :projects do
      verb :get
      path '/projects.json?limit=1000'
      handler (:ok) { |response| JSON.parse(response.body)['projects'] }
    end

    action :create_issue do
      verb :post
      path '/issues.json'
      body { |object| { issue: object } }
      handler (:created) { |response| JSON.parse(response.body)['issue'] }
    end

    action :update_issue do
      verb :put
      path '/issues/:id.json'
      body { |object| { issue: object } }
      handler (:ok) { |response| "Issue updated" }
      handler (404) { |response| "Issue not found" }
    end

    action :issues do
      verb :get
      path '/issues.json?assigned_to_id=me'
      handler (:ok) { |response| JSON.parse(response.body)['issues'] }
    end

    action :issue do
      verb :get
      path '/issues/:id.json'
      handler (:ok) { |response| JSON.parse(response.body)['issue'] }
      handler (404) { |response| "Issue not found" }
    end

    action :issue_journals do
      verb :get
      path '/issues/:id.json?include=journals'
      handler (:ok) { |response| JSON.parse(response.body)['issue'] }
      handler (404) { |response| "Issue not found" }
    end
  end
end
