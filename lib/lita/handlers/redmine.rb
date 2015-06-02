require "lita"

module Lita
  module Handlers
    class Redmine < Handler
      config :url
      config :secret_key

      route /redmine\sissue\s(\d+)/, :issue, help: { "redmine issue <issue #>" => "Displays issue id and subject" }
      route /redmine\sissue\sdetail\s(\d+)/, :issue_detail, help: { "redmine issue detail <issue #>" => "Displays issue detail" }
      route /redmine\sissue\slink\s(\d+)/, :issue_link, help: { "redmine issue link <issue #>" => "Displays issue link" }
      route /redmine\sissues/, :issues, help: {"redmine issues" => "List my issues" }
      route /redmine\sissue\snote\s(\d+)\s(.*)/, :issue_note, help: {"redmine issue note <issue #> note" => "Add note to issue" }
      route /redmine\sissue\sassign\s(\d+)\s(.*)/, :issue_assign, help: {"redmine issue assign <issue #> <firstname secondname>" => "Assign issue to user" }

      route /redmine\sregister\s([a-zA-z0-9])/, :register, help: { "redmine register <api token>" => "Register API token" }
      route /redmine\sunregister/, :unregister, help: { "redmine unregister" => "Unregister API token" }
      route /redmine\stoken/, :token, help: { "redmine token" => "Show registered token (PM)"}

      route /redmine\sinfo/, :info, help: {"redmine info" => "Display info"}
      route /.*\#(\d+).*/, :issue_mention, help: {"<something>#<issue #><something>" => "Displays issue subject" }

      def info(response)
        response.reply("Lita Redmine Bot by NetBrick")
      end

      # show issue detail
      def issue(response)
        apitoken = get_user_token(response.user.id)
        issue_id = response.matches.flatten.first
        issue = get_issue(config.url, apitoken, issue_id)
        message = issue.nil? ? "" : "#{issue['id']}: (#{issue['project']['name']}) #{issue["subject"]}"
        response.reply message
      end

      def issue_detail(response)
        apitoken = get_user_token(response.user.id)
        if apitoken.empty? 
          response.reply_privately "First run (PM): redmine register <apikey>"
        else
          issue_id = response.matches.flatten.first
          issue = get_issue(config.url, apitoken, issue_id)
          message = issue.nil? ? "" : "#{issue['id']}: (#{issue['project']['name']}) #{issue["subject"]}\n#{issue['description']}"
        end
        response.reply message
      end

      def issue_link(response)
        response.reply "Issue ##{response.matches.flatten.first}: #{config.url}/issues/#{response.matches.flatten.first}"
      end

      def issue_assign(response)
        apitoken = get_user_token(response.user.id)
        issue_id = response.matches.flatten[0]
        name = response.matches.flatten[1]
        user_id = get_user_by_name(config.url, apitoken, name)
        if user_id 
          msg = reassign(config.url, apitoken, issue_id, user_id)
          response.reply msg
        else
          response.reply "Unable to find user by name"
        end
      end

      def issue_mention(response)
        apitoken = get_user_token(response.user.id)
        issue_id = response.matches.flatten.first
        issue =  get_issue(config.url, apitoken, issue_id)
        response.reply "##{issue_id}: #{issue['subject']}"
      end

      def issue_note(response)
        apitoken = get_user_token(response.user.id)
        issue_id = response.matches.flatten[0]
        issue_note = response.matches.flatten[1]
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

      def register(response)
        api_token = response.args[1]
        user_id = response.user.id
        message = "Registered: #{user_id} url #{config.url}"
        redis.set("user_#{user_id}",api_token)
        response.reply message
      end

      def token(response)
        user_id = response.user.id
        apitoken = redis.get("user_#{user_id}")
        response.reply_privately "Token: #{apitoken}"
      end

      def unregister(response)
        user_id = response.user.id
        message = "Unregistered: #{user_id}"
        redis.set("user_#{user_id}","")
        response.reply message
      end

      def get_user_token(user_id)
        redis.get("user_#{user_id}")
      end

      def get_issue(url, apikey, issue_id)
        apikey_header = "X-Redmine-API-Key"
        issue_url = URI.parse("#{url}/issues/#{issue_id}")
        issue_json_url = "#{issue_url}.json"
        http_resp = http.get(issue_json_url, {}, { apikey_header => apikey })
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

      def get_issues(url, apikey)
        apikey_header = "X-Redmine-API-Key"
        issue_url = URI.parse("#{url}/issues.json")
        http_resp = http.get(issue_url, { "assigned_to_id" => "me" }, { apikey_header => apikey })
        issues = []
        case http_resp.status
        when 200
          resp = MultiJson.load(http_resp.body)
          resp['issues'].each do |issue|
            issues << issue
          end
        when 404
          message = "Issue ##{issue_id} does not exist"
        when 401
          message = "Issue ##{issue_id} needs authorization (possible wrong token)"
        else
          message = "Failed to fetch #{issue_json_url} (#{http_resp.status})"
        end
        issues
      end

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
    end
    Lita.register_handler(Redmine)
  end
end
