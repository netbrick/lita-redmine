require 'resource_kit'
require 'faraday'
require 'json'

class RedmineResource < ResourceKit::Resource
  resources do
    default_handler (401) { |response| { resource_error: "Wrong API token, please register new one" } }
    default_handler (403) { |response| { resource_error: "You are not authorized to do this action" } }
    default_handler (404) { |response| { resource_error: "Server responded with error code 404, please check you have correct parameters" } }
    default_handler (422) { |response| { resource_error: "Wrong parameters" } }
    default_handler { |response| { resource_error: "Unknown error, status: #{response.status}" } }

    action :list do
      verb :get
      path '/:object.json?limit=1000'
      handler (:ok) { |response| JSON.parse(response.body) }
    end

    action :create_entry do
      verb :post
      path '/time_entries.json'
      body { |object| { time_entry: object } }
      handler (:created) { |response| { message: "Time entry created" } }
    end

    action :users do
      verb :get
      path '/users.json?limit=1000'
      handler (:ok) { |response| JSON.parse(response.body) }
    end

    action :projects do
      verb :get
      path '/projects.json?limit=1000'
      handler (:ok) { |response| JSON.parse(response.body) }
    end

    action :create_issue do
      verb :post
      path '/issues.json'
      body { |object| { issue: object } }
      handler (:created) { |response| JSON.parse(response.body) }
    end

    action :update_issue do
      verb :put
      path '/issues/:id.json'
      body { |object| { issue: object } }
      handler (:ok) { |response| { message: "Issue updated" } }
    end

    action :issues do
      verb :get
      path '/issues.json?assigned_to_id=me'
      handler (:ok) { |response| JSON.parse(response.body) }
    end

    action :issue do
      verb :get
      path '/issues/:id.json'
      handler (:ok) { |response| JSON.parse(response.body) }
    end

    action :issue_journals do
      verb :get
      path '/issues/:id.json?include=journals'
      handler (:ok) { |response| JSON.parse(response.body) }
    end
  end
end
