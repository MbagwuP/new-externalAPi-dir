# HealthCheck

HealthCheck is a rack middleware based off of the [Cepa Health Check](https://github.com/jonathannen/cepa-health) gem.

## Installation

Add this line to your application's Gemfile:

    gem 'health_check', git: 'git@github.com:CareCloud/health_check.git'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install health_check, git: 'git@github.com:CareCloud/health_check.git'

## Usage

Add `vitals.yml` file to your config directory.
There are 2 severity levels to choose from: **warn** and **critical**.  If no severity is defined the default is warn.
A list of probes to choose from is located in the [probe](https://github.com/CareCloud/health_check/tree/master/probes) directory.

```ruby
# vitals.yml
development:
    probes:
        - "[probe]:[severity]"
```

Defining your own probe is as simple as...

```ruby
# custom_probe.rb
# Get creative with your probes
module Probes
  class CustomProbe < Probes::Probe
    def probe
      is_up = true
      err_msg = "Service is down"
      record(*["Service", is_up, is_up ? "Service is active." : err_msg])
      self
    end
  end
end 
```

... and placing it in then probe directory.

*Coming soon will be the ability to add and override probes*

Load configuration file and initialize the health check service.

```ruby
config = YAML.load_file(File.join('path', 'to', 'vitals.yml'))
HealthCheck.config = config[ENV['RACK_ENV']]
HealthCheck.start_health_monitor
```

Currently this gem for Rack-based applications (e.g. Sinatra Framework).  Add the following to your config.ru.

```ruby
use HealthCheck::Middleware, description: {service: "Service API", description: "API Service", version: `git describe`.strip}
```

Three endpoints are now available

1. `hostname/health_check`
2. `hostname/lb_check`
3. `hostname/ping`

## Contributing

1. Fork it ( http://github.com/CareCloud/health_check/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
