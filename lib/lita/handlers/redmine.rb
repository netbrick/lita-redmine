require "lita"

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
        response.reply("Lita Redmine Bot by NetBrick")
      end

      # show issue subject
      def issue(response)
        apitoken = get_user_token(response.user.id)
        issue_id = response.matches.flatten[1]
        issue = get_issue(config.url, apitoken, issue_id)
        message = issue.nil? ? "" : "#{issue['id']}: (#{issue['project']['name']}) #{issue["subject"]}"
        response.reply message
      end

      # show issue subject and description
      def issue_detail(response)
        apitoken = get_user_token(response.user.id)
        if apitoken.empty? 
          response.reply_privately "First run (PM): redmine register <apikey>"
        else
          issue_id = response.matches.flatten[1]
          issue = get_issue(config.url, apitoken, issue_id)
          message = issue.nil? ? "" : "#{issue['id']}: (#{issue['project']['name']}) #{issue["subject"]}\n#{issue['description']}"
        end
        response.reply message
      end

      # show issue subject and description
      def issue_journal(response)
        apitoken = get_user_token(response.user.id)
        if apitoken.empty? 
          response.reply_privately "First run (PM): redmine register <apikey>"
        else
          issue_id = response.matches.flatten[1]
          issue = get_issue(config.url, apitoken, issue_id, true)
          message = issue.nil? ? "" : "#{issue['id']}: (#{issue['project']['name']}) #{issue["subject"]}\n#{issue['description']}"
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
        apitoken = get_user_token(response.user.id)
        issue_id = response.matches.flatten[1]
        name = response.matches.flatten[2]
        user_id = get_user_by_name(config.url, apitoken, name)
        if user_id 
          msg = reassign(config.url, apitoken, issue_id, user_id)
          response.reply msg
        else
          response.reply "Unable to find user by name"
        end
      end

      # create issue in project specified by name
      def issue_new(response)
        apitoken = get_user_token(response.user.id)
        project = response.matches.flatten[1]
        subject = response.matches.flatten[2]
        description = response.matches.flatten[3]
        project_id = get_project_by_name(config.url, apitoken, project)
        if project_id 
          msg = create_issue(config.url, apitoken, project_id, subject, description)
          response.reply msg
        else
          response.reply "Unable to find project by name"
        end
      end

      # show issue subject when someone mention issue #
      def issue_mention(response)
        apitoken = get_user_token(response.user.id)
        issue_id = response.matches.flatten[1]
        issue =  get_issue(config.url, apitoken, issue_id)
        response.reply "##{issue_id}: (#{issue['project']['name']}) #{issue['subject']}"
      end

      # write new issue note
      def issue_note(response)
        apitoken = get_user_token(response.user.id)
        issue_id = response.matches.flatten[1]
        issue_note = response.matches.flatten[2]
        message = add_issue_note(config.url, apitoken, issue_id, issue_note)
        response.reply message
      end

      # list issues of user
      def issues(response)
        apitoken = get_user_token(response.user.id)
        message = ""
        issues = get_issues(config.url, apitoken) 
        issues.each do |issue|
          message << "#{issue['id']}: (#{issue['project']['name']}) #{issue['subject']}\n"
        end
        response.reply message
      end

      # list projects of user
      def projects(response)
        apitoken = get_user_token(response.user.id)
        message = ""
        projects = get_projects(config.url, apitoken) 
        projects.each do |prj|
          message << "#{prj['id']}: (#{prj['name']})\n"
        end
        response.reply_privately message
      end

      # save user API token into redis
      def register(response)
        api_token = response.args[1]
        user_id = response.user.id
        message = "Registered: #{user_id} url #{config.url}"
        redis.set("user_#{user_id}",api_token)
        response.reply message
      end

      # send saved API token to DM/PM
      def token(response)
        user_id = response.user.id
        apitoken = redis.get("user_#{user_id}")
        response.reply_privately "Token: #{apitoken}"
      end

      # delete saved API token
      def unregister(response)
        user_id = response.user.id
        message = "Unregistered: #{user_id}"
        redis.set("user_#{user_id}","")
        response.reply message
      end

      # retrieve user API token from redis
      def get_user_token(user_id)
        redis.get("user_#{user_id}")
      end

      # get issue information via API
      def get_issue(url, apikey, issue_id, journal=false)
        apikey_header = "X-Redmine-API-Key"
        issue_url = URI.parse("#{url}/issues/#{issue_id}")
        issue_json_url = "#{issue_url}.json"
        http_resp = http.get(issue_json_url, journal ? {"include"=>"journals"} : {} , { apikey_header => apikey })
        case http_resp.status
        when 200
          resp = MultiJson.load(http_resp.body)
          issue = resp['issue']
        when 404
          message = "Issue ##{issue_id} does not exist"
        when 401
          message = "Issue ##{issue_id} needs authorization (possible wrong token)"
        else
          message = "Failed to fetch #{issue_json_url} (#{http_resp.status})"
        end
        issue
      end

      # get issues list via API
      def get_issues(url, apikey)
        apikey_header = "X-Redmine-API-Key"
        issue_url = URI.parse("#{url}/issues.json")
        http_resp = http.get(issue_url, { "assigned_to_id" => "me" }, { apikey_header => apikey })
        issues = []
        if http_resp.status == 200
          resp = MultiJson.load(http_resp.body)
          resp['issues'].each do |issue|
            issues << issue
          end
        else
          message = "Failed to fetch #{issue_json_url} (#{http_resp.status})"
        end
        issues
      end

      # get projects list via API
      def get_projects(url, apikey)
        apikey_header = "X-Redmine-API-Key"
        issue_url = URI.parse("#{url}/projects.json")
        http_resp = http.get(issue_url, { "limit" => 1000 }, { apikey_header => apikey })
        projects = []
        if http_resp.status == 200
          resp = MultiJson.load(http_resp.body)
          resp['projects'].each do |prj|
            projects << prj
          end
        else
          message = "Failed to fetch #{issue_json_url} (#{http_resp.status})"
        end
        projects
      end


      # add new note to issue via API
      def add_issue_note(url, apikey, issue_id, issue_note)
        apikey_header = "X-Redmine-API-Key"
        issue_url = URI.parse("#{url}/issues/#{issue_id}.json")
        update = {"issue" => {"notes" => issue_note}}
        resp = http.put(issue_url, update, {apikey_header => apikey})
        if resp.status == 200 || resp.status == 201 
          message = "OK"
        else
          message = "ERROR"
        end
      end

      # assign issue to user via API
      def reassign(url, apikey, issue_id, user_id)
        apikey_header = "X-Redmine-API-Key"
        issue_url = URI.parse("#{url}/issues/#{issue_id}.json")
        update = {"issue" => {"assigned_to_id" => user_id }}
        resp = http.put(issue_url, update, { apikey_header => apikey })
        if resp.status == 200 || resp.status == 201 
          message = "OK"
        else
          message = "Unable to reassign"
        end
      end

      # create issue via API
      def create_issue(url, apikey, project_id, subject, description)
        apikey_header = "X-Redmine-API-Key"
        issue_url = URI.parse("#{url}/issues.json")
        update = {"issue" => {"project_id" => project_id.to_i, "subject" => subject, "description" => description, "tracker_id" => 1, "priority_id" => 1, "status_id" => 1 }}
        resp = http.post(issue_url, update, { apikey_header => apikey })
        if resp.status == 200 || resp.status == 201 
          message = "OK"
        else
          message = "Unable to create"
        end
      end

      # find user id by name via API
      def get_user_by_name(url, apikey, name)
        apikey_header = "X-Redmine-API-Key"
        url = URI.parse("#{url}/users.json")
        resp = http.get(url, {"limit" => 1000 }, {apikey_header => apikey})
        id = nil
        if resp.status == 200
          resp = MultiJson.load(resp.body)
        else
          return nil
        end
        resp['users'].each do |user|
          id = user['id'] if (user['firstname']+" "+user['lastname']) == name
        end
        id
      end
      # find user id by name via API
      def get_project_by_name(url, apikey, name)
        apikey_header = "X-Redmine-API-Key"
        url = URI.parse("#{url}/projects.json")
        resp = http.get(url, {"limit" => 1000 }, {apikey_header => apikey})
        id = nil
        if resp.status == 200
          resp = MultiJson.load(resp.body)
        else
          return nil
        end
        resp['projects'].each do |prj|
          id = prj['id'] if (prj['name']) == name
        end
        id
      end


    end
    Lita.register_handler(Redmine)
  end
end
