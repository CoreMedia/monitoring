# ruby-grafana-api


## Description

A simple Ruby wrapper for the [Grafana](http://docs.grafana.org/reference/http_api/)  HTTP API.



## Comments/Notes

If you come across a bug or if you have a request for a new feature, please open an issue.


## Methods & Usage Examples

#### Creating an instance of the grafana api client:
```ruby
config = {
  :host              => grafanaHost,
  :port              => grafanaPort,
  :user              => grafanaApiUser,
  :password          => grafanaApiPassword,
  :debug             => false,
  :timeout           => 10,
  :ssl               => false,
  :url_path          => grafanaUrlPath,
  :templateDirectory => grafanaTemplatePath,
  :memcacheHost      => memcacheHost,
  :memcachePort      => memcachePort,
  :mqHost            => mqHost,
  :mqPort            => mqPort,
  :mqQueue           => mqQueue
}
g = Grafana::Client.new( config )
```

#### Connecting to Grafana using an API key:
```ruby
config = {
  :host     => grafanaHost,
  :port     => grafanaPort,
  :user     => nil,
  :password => nil,
  :debug    => false,
  :timeout  => 3,
  :ssl      => false,
  :url_path => '/grafana',
  :headers  => {
    :authorization => "Bearer eiJrIjoidTBsQWpicGR0SzFXD29aclExTjk1cVliMWREUVp0alAiLCJuIjoiR8JhZGFzaG3yFiwiawQIOjE2"
  }
}

g = Grafana::Client.new('[GRAFANA_HOST]', [GRAFANA_PORT], nil, nil, options)
```
*user and pass attributes are ignored when specifying Authorization header*

#### Individual Module Documentation

* [Admin](docs/ADMIN.md)
* [Dashboard](docs/DASHBOARD.md)
* [Datasource](docs/DATASOURCE.md)
* [Frontend](docs/FRONTEND.md)
* [Login](docs/LOGIN.md)
* [Organization](docs/ORGANIZATION.md)
* [Organizations](docs/ORGANIZATIONS.md)
* [Snapshot](docs/SNAPSHOT.md)
* [User](docs/USER.md)
* [Users](docs/USERS.md)


## License


