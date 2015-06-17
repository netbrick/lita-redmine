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
redmine|rm issue <issue #> - Displays issue id and subject
redmine|rm issue detail <issue #> - Displays issue detail
redmine|rm issue journal <issue #> - Displays issue journal
redmine|rm issue link <issue #> - Displays issue link
redmine|rm issue new [Project name] [Subject] [Description] - Create new issue
redmine|rm issues - List my issues
redmine|rm issue note <issue #> note - Add note to issue
redmine|rm issue assign <issue #> <firstname secondname> - Assign issue to user
redmine|rm projects - List my projects
redmine|rm info - Display info
<something>#<issue #><something> - Displays issue subject

redmine|rm register <api token> - Register API token
redmine|rm unregister - Unregister API token
redmine|rm token - Show registered token (PM)
```
