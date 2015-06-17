require "lita"
require "#{File.dirname(__FILE__)}/../../resources/redmine_resource"

module Lita
  module Handlers
    class Redmine < Handler
      config :url
      config :secret_key

      route /^(redmine|rm)\sissue\s(\d+)/, :issue, help: { "redmine|rm issue <issue #>" => "Displays issue id and subject" }
      route /^(redmine|rm)\sissue\sdetail\s(\d+)/, :issue_detail, help: { "redmine|rm issue detail <issue #>" => "Displays issue detail" }
      route /^(redmine|rm)\sissue\sjournal\s(\d+)/, :issue_journal, help: { "redmine|rm issue journal <issue #>" => "Displays issue journal" }
      route /^(redmine|rm)\sissue\slink\s(\d+)/, :issue_link, help: { "redmine|rm issue link <issue #>" => "Displays issue link" }
      route /^(redmine|rm)\sissue\snew\s\[(.*)\]\s\[(.*)\]\s\[(.*)\]/, :issue_new, help: { "redmine|rm issue new [Project name] [Subject] [Description]" => "Create new issue" }
      route /^(redmine|rm)\sissues/, :issues, help: {"redmine|rm issues" => "List my issues" }
      route /^(redmine|rm)\sissue\snote\s(\d+)\s(.*)/, :issue_note, help: {"redmine|rm issue note <issue #> note" => "Add note to issue" }
      route /^(redmine|rm)\sissue\sassign\s(\d+)\s(.*)/, :issue_assign, help: {"redmine|rm issue assign <issue #> <firstname secondname>" => "Assign issue to user" }

      route /^(redmine|rm)\sprojects/, :projects, help: {"redmine|rm projects" => "List my projects" }

      route /^(redmine|rm)\sregister\s([a-zA-z0-9])/, :register, help: { "redmine|rm register <api token>" => "Register API token" }
      route /^(redmine|rm)\sunregister/, :unregister, help: { "redmine|rm unregister" => "Unregister API token" }
      route /^(redmine|rm)\stoken/, :token, help: { "redmine|rm token" => "Show registered token (PM)"}

      route /^(redmine|rm)\sinfo/, :info, help: {"redmine|rm info" => "Display info"}
      route /.*\#(\d+).*/, :issue_mention, help: {"<something>#<issue #><something>" => "Displays issue subject" }

      def info(response)
        response.reply "Lita Redmine Bot by NetBrick"
      end

      # show issue subject
      def issue(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          message =  "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[1]
          issue = resource.issue(id: issue_id)

          # We always get response, on error response contains error message
          message = issue['id'].nil? ? issue : "#{issue['id']}: (#{issue['project']['name']}) #{issue["subject"]}"
        end

        response.reply message
      end

      # show issue subject and description
      def issue_detail(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          message = "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[1]
          issue = resource.issue(id: issue_id)

          message = issue['id'].nil? ? issue : "#{issue['id']}: (#{issue['project']['name']}) #{issue["subject"]}\n#{issue['description']}"
        end

        response.reply message
      end

      # show issue subject and description
      def issue_journal(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          message = "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[1]
          issue = resource.issue(id: issue_id)

          message = issue['id'].nil? ? issue : "#{issue['id']}: (#{issue['project']['name']}) #{issue["subject"]}\n#{issue['description']}"
          issue['journals'].each do |j|
            if !j['notes'].empty?
              message = message + "\n"
              message = message + "Author: #{j['user']['name']}\n"
              message = message + j['notes'] + "\n"
            end
         end
       end

       response.reply message
      end

      # show issue link
      def issue_link(response)
        response.reply "Issue ##{response.matches.flatten[1]}: #{config.url}/issues/#{response.matches.flatten[1]}"
      end

      # assign issue to user specified by name
      def issue_assign(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          message = "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[1]
          name = response.matches.flatten[2]

          if user_id = get_user_by_name(name, resource)
            issue = resource.update_issue({ assigned_to_id: user_id }, id: issue_id)
            message = issue['id'].nil? ? issue : "Issue updated"
          else
            message =  "Unable to find user by name"
          end
        end

        response.reply message
      end

      # create issue in project specified by name
      def issue_new(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          message = "Token not registered, register token via 'redmine register <api_token>'"
        else
          project_name = response.matches.flatten[1]
          subject = response.matches.flatten[2]
          description = response.matches.flatten[3]

          if project_id = get_project_by_name(project_name, resource)
            issue = resource.create_issue({ project_id: project_id, subject: subject, description: description})
            message = issue['id'].nil? ? issue : "Issue created with id #{issue['id']}"
          else
            message = "Unable to find project by name"
          end
        end

        response.reply message
      end

      # show issue subject when someone mention issue #
      def issue_mention(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          message = "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[0]
          issue = resource.issue(id: issue_id)

          message = issue['id'].nil? ? issue : "#{issue['id']}: (#{issue['project']['name']}) #{issue["subject"]}"
        end

        response.reply message
      end

      # write new issue note
      def issue_note(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          message = "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[1]
          issue_note = response.matches.flatten[2]

          issue = resource.update_issue({ notes: issue_note }, id: issue_id)
          message = issue['id'].nil? ? issue : "Issue note created"
        end

        response.reply message
      end

      # list issues of user
      def issues(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          message = "Token not registered, register token via 'redmine register <api_token>'"
        else
          issues = resource.issues

          message = ''
          issues.each do |issue|
            message << "#{issue['id']}: (#{issue['project']['name']}) #{issue['subject']}\n"
          end
        end

        response.reply message
      end

      # list projects of user
      def projects(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          message = "Token not registered, register token via 'redmine register <api_token>'"
        else
          projects = resource.projects

          message = ''
          projects.each do |prj|
            message << "#{prj['id']}: (#{prj['name']})\n"
          end
        end

        response.reply message
      end

      # save user API token into redis
      def register(response)
        user_id = response.user.id
        api_token = response.args[1]

        redis.set("user_#{user_id}", api_token)

        message = "Registered: #{user_id} url #{config.url}"
        response.reply message
      end

      # send saved API token to DM/PM
      def token(response)
        user_id = response.user.id

        token = redis.get("user_#{user_id}")

        message = "Token: #{token}"
        response.reply_privately message
      end

      # delete saved API token
      def unregister(response)
        user_id = response.user.id

        redis.set("user_#{user_id}", "")

        message = "Unregistered: #{user_id}"
        response.reply message
      end

      # retrieve user API token from redis
      def get_user_token(user_id)
        token = redis.get("user_#{user_id}")

        if !token.nil? && !token.empty?
          connection = Faraday.new(url: config.url, headers: { "X-Redmine-API-Key" => token })
          resource = RedmineResource.new(connection: connection)
        else
          resource = nil
        end
      end

      # find user id by name via API
      def get_user_by_name(name, resource)
        users = resource.users

        id = nil
        users.each do |user|
          user_name = user['firstname'] + " " + user['lastname']
          id = user['id'] if user_name == name
        end

        id
      end

      # find user id by name via API
      def get_project_by_name(name, resource)
        projects = resource.projects

        id = nil
        projects.each do |prj|
          id = prj['id'] if (prj['name']) == name
        end

        id
      end
    end

    Lita.register_handler(Redmine)
  end
end
