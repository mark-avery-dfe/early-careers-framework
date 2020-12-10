[![Build Status](https://travis-ci.org/DFE-Digital/govuk-rails-boilerplate.svg?branch=master)](https://travis-ci.com/DFE-Digital/govuk-rails-boilerplate)

# Early careers framework

## Prerequisites

- Ruby 2.7.1
- PostgreSQL
- NodeJS 12.13.x
- Yarn 1.12.x
- Docker

## Setting up the app in development

### Without docker

1. Run `bundle install` to install the gem dependencies
2. Run `yarn` to install node dependencies
3. Create `.env` file - copy `.env.template`. Set your database password and user in the `.env` file
4. Run `bin/rails db:setup` to set up the database development and test schemas, and seed with test data
5. Run `bundle exec rails server` to launch the app on http://localhost:3000
6. Run `./bin/webpack-dev-server` in a separate shell for faster compilation of assets

### With docker
1. Run `docker-compose build` to build the web image
2. Run `docker-compose run --rm web bundle exec rake db:setup` to setup the database
3. Run `docker-compose up` to start the service

It should be possible to run just the database from docker, if you want to.
Check docker-compose file for username and password to put in your `.env` file.

If you want to seed the database you can either run `db:drop` and `db:setup` tasks with your preferred method,
or `db:seed`. 

### Govuk Notify
Register on [GOV.UK Notify](https://www.notifications.service.gov.uk). 
Ask someone from the team to add you to our service.
Generate an api key for yourself and set it in your `.env` file.

### Set up git hooks
Run `git config core.hooksPath .githooks` to use the included git hooks.

### Test displaying markdown with govspeak 
Run your app locally. Go to http://localhost:3000/govspeak_test. Enter your markdown into the text area,
click "See preview". Voila!

## Whats included in this boilerplate?

- Rails 6.0 with Webpacker
- [GOV.UK Frontend](https://github.com/alphagov/govuk-frontend)
- RSpec
- Dotenv (managing environment variables)
- Travis with Heroku deployment

## Running specs, linter(without auto correct) and annotate models and serializers
```
bundle exec rake
```

## Running specs
```
bundle exec rspec
```

## Linting

It's best to lint just your app directories and not those belonging to the framework, e.g.

```bash
bundle exec rubocop app config db lib spec Gemfile --format clang -a

or

bundle exec scss-lint app/webpacker/styles
```

## Deploying on GOV.UK PaaS

### Prerequisites

- Your department, agency or team has a GOV.UK PaaS account
- You have a personal account granted by your organisation manager
- You have downloaded and installed the [Cloud Foundry CLI](https://github.com/cloudfoundry/cli#downloads) for your platform

### Deploy

1. Run `cf login -a api.london.cloud.service.gov.uk -u USERNAME`, `USERNAME` is your personal GOV.UK PaaS account email address
2. Run `bundle package --all` to vendor ruby dependencies
3. Run `yarn` to vendor node dependencies
4. Run `bundle exec rails webpacker:compile` to compile assets
5. Run `cf push` to push the app to Cloud Foundry Application Runtime

Check the file `manifest.yml` for customisation of name (you may need to change it as there could be a conflict on that name), buildpacks and eventual services (PostgreSQL needs to be [set up](https://docs.cloud.service.gov.uk/deploying_services/postgresql/)).

The app should be available at https://govuk-rails-boilerplate.london.cloudapps.digital
