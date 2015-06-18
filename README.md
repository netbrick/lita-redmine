# lita-redmine

Lita Redmine Plugin - Redmine handlers

## Installation

Add lita-redmine to your Lita instance's Gemfile:

``` ruby
gem "lita-redmine", git: "https://github.com/netbrick/lita-redmine", branch: "master"
```

## Configuration

add into lita_config.rb Redmine URL

``` ruby
Lita.configure do |config|
...
  config.handlers.redmine.url = "https://redmine.site.cz"
...
end
```

## Usage

```
redmine|rm list <object #> - Redmine list objects, calls Redmine API as /:object.json
redmine|rm time entry new [Issue_id] [Hours] [Activity name] [Comment] - Create new time entry with today's date

redmine|rm issue <issue #> - Displays issue id and subject
redmine|rm issue close <issue #> - Selects first status with closing attribute and updates issue to this status
redmine|rm issue detail <issue #> - Displays issue detail
redmine|rm issue journal <issue #> - Displays issue journal
redmine|rm issue link <issue #> - Displays issue link
redmine|rm issue new [Project name] [Subject] [Description] <firstname secondname> - Create new issue, name is optional and selects user to assign issue to
redmine|rm issue state change <issue #> <status_name> - Change issue status to specified

redmine|rm issues - List my issues
redmine|rm issue note <issue #> note - Add note to issue
redmine|rm issue assign <issue #> [firstname secondname] <note> - Assign issue to user, note is optional

redmine|rm projects - List my projects

redmine|rm register <api token> - Register API token
redmine|rm unregister - Unregister API token
redmine|rm token - Show registered token (PM)

redmine|rm info - Display info
<something>#<issue #><something> - Displays issue subject when mentoied in conversation
```
