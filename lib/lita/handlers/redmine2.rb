require "lita"
require "crypt/blowfish"
require "#{File.dirname(__FILE__)}/../../resources/redmine_resource"

module Lita
  module Handlers
    class Redmine2 < Handler
      config :url
      config :secret_key

      route /^(redmine|rm)\slist\s([a-zA-Z_]+)/, :list_objects, help: { "redmine|rm list <object #>" => "Redmine list objects, calls Redmine API as /:object.json" }

      route /^(redmine|rm)\stime entry\snew\s\[(\d+)\]\s\[([^\[\]]+)\]\s\[([^\[\]]+)\]\s\[([^\[\]]+)\]/, :time_entry_new, help: { "redmine|rm time entry new [Issue_id] [Hours] [Activity name] [Comment]" => "Create new time entry with today's date" }

      route /^(redmine|rm)\sissue\s(\d+)/, :issue, help: { "redmine|rm issue <issue #>" => "Displays issue id and subject" }
      route /^(redmine|rm)\sissue\sclose\s(\d+)/, :issue_close, help: { "redmine|rm issue close <issue #>" => "Selects first status with closing attribute and updates issue to this status" }
      route /^(redmine|rm)\sissue\sdetail\s(\d+)/, :issue_detail, help: { "redmine|rm issue detail <issue #>" => "Displays issue detail" }
      route /^(redmine|rm)\sissue\sjournal\s(\d+)/, :issue_journal, help: { "redmine|rm issue journal <issue #>" => "Displays issue journal" }
      route /^(redmine|rm)\sissue\slink\s(\d+)/, :issue_link, help: { "redmine|rm issue link <issue #>" => "Displays issue link" }
      route /^(redmine|rm)\sissue\snew\s\[([^\[\]]+)\]\s\[([^\[\]]+)\]\s\[([^\[\]]+)\](\s\[[^\[\]]+\])?/, :issue_new, help: { "redmine|rm issue new [Project name] [Subject] [Description] [Firstname Secondname]" => "Create new issue, name is optional and selects user to assign issue to" }
      route /^(redmine|rm)\sissue\sstate\schange\s\[(\d+)\]\s\[([^\[\]]+)\]/, :issue_change_state, help: {"redmine|rm issue state change [Issue_id] [Status_name]" => "Change issue status to specified" }
      route /^(redmine|rm)\sissues/, :issues, help: {"redmine|rm issues" => "List my issues" }
      route /^(redmine|rm)\sissue\snote\s\[(\d+)\]\s\[([^\[\]]+)\]/, :issue_note, help: {"redmine|rm issue note [Issue_id] [Note]" => "Add note to issue" }
      route /^(redmine|rm)\sissue\sassign\s\[(\d+)\]\s\[([^\[\]]+)\](\s\[[^\[\]]+\])?/, :issue_assign, help: {"redmine|rm issue assign [Issue_id] [Firstname Secondname] [Note]" => "Assign issue to user, note is optional" }

      route /^(redmine|rm)\sprojects/, :projects, help: {"redmine|rm projects" => "List my projects" }

      route /^(redmine|rm)\sregister\s([a-zA-z0-9])/, :register, help: { "redmine|rm register <api token>" => "Register API token" }
      route /^(redmine|rm)\sunregister/, :unregister, help: { "redmine|rm unregister" => "Unregister API token" }
      route /^(redmine|rm)\stoken/, :token, help: { "redmine|rm token" => "Show registered token (PM)"}

      route /^(redmine|rm)\sinfo/, :info, help: {"redmine|rm info" => "Display info"}
      route /.*\#(\d+).*/, :issue_mention, help: {"<something>#<issue #><something>" => "Displays issue subject when mentoied in conversation" }

      def info(response)
        response.reply "Lita Redmine Bot by NetBrick"
      end

      # get list of objects
      def list_objects(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          response.reply_privately "Token not registered, register token via 'redmine register <api_token>'"
        else
          object = response.matches.flatten[1]

          # Update route as there objects require 'enumerations' in the url
          if object == 'time_entry_activities' || object == 'issue_priorities'
            object = 'enumerations/' + object
          end

          message = resource.list(object: object)
          if message[:resource_error].nil?
            response.reply parse_list_objects(message)
          else
            response.reply_privately message[:resource_error]
          end
        end
      end

      # create new time entry
      def time_entry_new(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          response.reply_privately "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[1]
          hours = response.matches.flatten[2]
          activity_name = response.matches.flatten[3]
          comments = response.matches.flatten[4]

          if activity_id = get_activity_by_name(activity_name, resource)
            message = resource.create_entry({issue_id: issue_id, hours: hours, activity_id: activity_id, comments: comments})

            if message[:resource_error].nil?
              response.reply message[:message]
            else
              response.reply_privately message[:resource_error]
            end
          else
            response.reply_privately "Unable to find activity by specified name"
          end
        end
      end

      # show issue subject
      def issue(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          response.reply_privately "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[1]
          issue = resource.issue(id: issue_id)

          if issue[:resource_error].nil?
            issue = issue['issue']
            response.reply "#{issue['id']}: (#{issue['project']['name']}) #{issue["subject"]}"
          else
            response.reply_privately issue[:resource_error]
          end
        end
      end

      # show issue subject and description
      def issue_detail(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          response.reply_privately "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[1]
          issue = resource.issue(id: issue_id)

          if issue[:resource_error].nil?
            issue = issue['issue']
            response.reply "#{issue['id']}: (#{issue['project']['name']}) #{issue["subject"]}\n#{issue['description']}"
          else
            response.reply_privately issue[:resource_error]
          end
        end
      end

      # show issue subject and description
      def issue_journal(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          response.reply_privately "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[1]
          issue = resource.issue(id: issue_id)

          if issue[:resource_error].nil?
            issue = issue['issue']

            message = "#{issue['id']}: (#{issue['project']['name']}) #{issue["subject"]}\n#{issue['description']}"

            issue['journals'] = issue['journals'].nil? ? {} : issue['journals']
            issue['journals'].each do |j|
              if !j['notes'].nil? && !j['notes'].empty?
                message = message + "\n"
                message = message + "Author: #{j['user']['name']}\n"
                message = message + j['notes'] + "\n"
              end
            end

            response.reply message
          else
            response.reply_privately issue[:resource_error]
          end
       end
      end

      # show issue link
      def issue_link(response)
        response.reply "Issue ##{response.matches.flatten[1]}: #{config.url}/issues/#{response.matches.flatten[1]}"
      end

      # change status of issue
      def issue_change_state(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          response.reply_privately "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[1]
          status_name = response.matches.flatten[2]

          if status_id = get_status_by_name(status_name, resource)
            issue = resource.update_issue({ status_id: status_id }, id: issue_id)
            if issue[:resource_error].nil?
              response.reply issue[:message]
            else
              response.reply_privately issue[:resource_error]
            end
          else
            response.reply_privately "Unable to find status by specified name"
          end
        end
      end

      # close issue
      def issue_close(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          response.reply_privately "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[1]

          if status_id = get_closing_status_id(resource)
            issue = resource.update_issue({ status_id: status_id }, id: issue_id)
            if issue[:resource_error].nil?
              response.reply issue[:message]
            else
              response.reply_privately issue[:resource_error]
            end
          else
            response.reply_privately "Unable to find any closing status"
          end
        end
      end

      # assign issue to user specified by name
      def issue_assign(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          response.reply_privately "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[1]
          name = response.matches.flatten[2]
          note = response.matches.flatten[3].nil? ? "" : response.matches.flatten[3].strip
          note = note[1, note.length - 2]

          if user_id = get_user_by_name(name, resource)
            issue = resource.update_issue({ assigned_to_id: user_id, notes: note }, id: issue_id)
            if issue[:resource_error].nil?
              response.reply issue[:message]
            else
              response.reply_privately issue[:resource_error]
            end
          else
            response.reply_privately "Unable to find user by name"
          end
        end
      end

      # create issue in project specified by name
      def issue_new(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          response.reply_privately "Token not registered, register token via 'redmine register <api_token>'"
        else
          project_name = response.matches.flatten[1]
          subject = response.matches.flatten[2]
          description = response.matches.flatten[3]
          assignee_name = response.matches.flatten[4].nil? ? "" : response.matches.flatten[4].strip
          assignee_name = assignee_name[1, assignee_name.length - 2]

          project_id = get_project_by_name(project_name, resource)
          user_id = get_user_by_name(assignee_name, resource)

          if project_id
            issue = resource.create_issue({ project_id: project_id, subject: subject, description: description, assigned_to_id: user_id })
            if issue[:resource_error].nil?
              issue = issue['issue']
              response.reply "Issue created with id #{issue['id']}"
            else
              response.reply_privately issue[:resource_error]
            end
          else
            response.reply_privately "Unable to find project by name"
          end
        end
      end

      # show issue subject when someone mention issue #
      def issue_mention(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          response.reply_privately "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[0]
          issue = resource.issue(id: issue_id)

          if issue[:resource_error].nil?
            issue = issue['issue']
            response.reply "#{issue['id']}: (#{issue['project']['name']}) #{issue["subject"]}"
          else
            response.reply_privately issue[:resource_error]
          end
        end
      end

      # write new issue note
      def issue_note(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          response.reply_privately "Token not registered, register token via 'redmine register <api_token>'"
        else
          issue_id = response.matches.flatten[1]
          issue_note = response.matches.flatten[2]

          issue = resource.update_issue({ notes: issue_note }, id: issue_id)
          if issue[:resource_error].nil?
            response.reply issue[:message]
          else
            response.reply_privately issue[:resource_error]
          end
        end
      end

      # list issues of user
      def issues(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          response.reply_privately "Token not registered, register token via 'redmine register <api_token>'"
        else
          issues = resource.issues

          if issues[:resource_error].nil?
            message = ''
            issues = issues['issues'].nil? ? {} : issues['issues']
            issues.each do |issue|
              message << "#{issue['id']}: (#{issue['project']['name']}) #{issue['subject']}\n"
            end

            response.reply message
          else
            response.reply_privately issues[:resource_error]
          end
        end
      end

      # list projects of user
      def projects(response)
        resource = get_user_token(response.user.id)

        if resource.nil?
          response.reply_privately "Token not registered, register token via 'redmine register <api_token>'"
        else
          projects = resource.projects

          if projects[:resource_error].nil?
            message = ''
            projects = projects['projects'].nil? ? {} : projects['projects']
            projects.each do |prj|
              message << "#{prj['id']}: (#{prj['name']})\n"
            end

            response.reply message
          else
            response.reply_privately projects[:resource_error]
          end
        end
      end

      # save user API token into redis
      def register(response)
        user_id = response.user.id
        api_token = response.args[1]

        api_token = encryptor.encrypt_string(api_token)
        redis.set("user_#{user_id}", api_token)

        message = "Registered: #{user_id} url #{config.url}"
        response.reply message
      end

      # send saved API token to DM/PM
      def token(response)
        user_id = response.user.id

        token = redis.get("user_#{user_id}")
        token = decrypt_token(token, user_id)

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
        token = decrypt_token(token, user_id)

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
        users = users[:resource_error].nil? ? users['users'] : {}

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
        projects = projects[:resource_error].nil? ? projects['projects'] : {}

        id = nil
        projects.each do |prj|
          id = prj['id'] if prj['name'] == name
        end

        id
      end

      # get activity id by name
      def get_activity_by_name(name, resource)
        activities = resource.list(object: 'enumerations/time_entry_activities')
        activities = activities[:resource_error].nil? ? activities['time_entry_activities'] : {}

        activity_id = nil
        activities.each do |a|
          activity_id = a['id'] if a['name'] == name
        end

        activity_id
      end

      def get_status_by_name(name, resource)
        states = resource.list(object: 'issue_statuses')
        states = states['issue_statuses'].nil? ? [] : states['issue_statuses']

        status_id = nil
        states.each do |s|
          status_id = s['id'] if s['name'] == name
        end

        status_id
      end

      # get status id with close attribute
      def get_closing_status_id(resource)
        states = resource.list(object: 'issue_statuses')
        states = states['issue_statuses'].nil? ? [] : states['issue_statuses']

        status_id = nil
        states.each do |s|
          if s['is_closed']
            status_id = s['id']
            break
          end
        end

        status_id
      end

      # parse list of objects
      def parse_list_objects(list)
        message = ''

        case list.keys[0]
        when 'users'
          users = list['users']
          users.each do |u|
            message << "#{u['id']}: #{u['firstname']} #{u['lastname']}\n"
          end
        when 'issues'
          issues = list['issues']
          issues.each do |i|
            message << "#{i['id']}: (#{i['project']['name']}) #{i['subject']}\n"
          end
        when 'projects'
          projects = list['projects']
          projects.each do |p|
            message << "#{p['id']}: (#{p['name']})\n"
          end
        when 'time_entries'
          time_entries = list['time_entries']
          time_entries.each do |t|
            issue_id = t['issue'].nil? ? "" : t['issue']['id']
            message << "Issue_id: #{issue_id}, spent_on: #{t['spent_on']}, hours: #{t['hours']}\n"
          end
        when 'time_entry_activities'
          time_entry_activities = list['time_entry_activities']
          time_entry_activities.each do |t|
            message << "Name: #{t['name']}\n"
          end
        when 'issue_statuses'
          issue_statuses = list['issue_statuses']
          issue_statuses.each do |s|
            message << "Name: #{s['name']}, closes issue: #{s['is_closed'] ? 'yes' : 'no'}\n"
          end
        when 'trackers'
          trackers = list['trackers']
          trackers.each do |t|
            message << "Name: #{t['name']}\n"
          end
        when 'issue_priorities'
          issue_priorities = list['issue_priorities']
          issue_priorities.each do |p|
            message << "Name: #{p['name']}\n"
          end
        else
          message = 'Currently unsupported'
        end

        message
      end

      # try decrypt token and if not ecrypted, update redis record
      def decrypt_token(token, user_id)
        decrypted_token = encryptor.decrypt_string(token)
      rescue
        encrypted_token = token.nil? ? '' : encryptor.encrypt_string(token)
        redis.set("user_#{user_id}", encrypted_token)

        token
      end

      # encrypting mechanism
      def encryptor
        secret_key = config.secret_key.nil? ? "BqJYq7FQjhXuaPSkbTxw" : config.secret_key
        @encryptor ||= Crypt::Blowfish.new(secret_key)
      end
    end

    Lita.register_handler(Redmine2)
  end
end
