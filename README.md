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
redmine issue <issue #> - Displays issue id and subject
redmine issue detail <issue #> - Displays issue detail
redmine issue link <issue #> - Displays issue link
redmine issue note <issue #> note - Add note to issue
redmine issue assign <issue #> <firstname secondname> - Assign issue to user
redmine issues - List my issues
redmine info - Display info
<something>#<issue #><something> - Displays issue subject

redmine register <api token> - Register API token
redmine unregister - Unregister API token
redmine token - Show registered token (PM)
```
