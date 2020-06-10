[![Build Status](https://travis-ci.com/rreinhardt9/demux.svg?branch=master)](https://travis-ci.com/rreinhardt9/demux)

# Demux

Demux is under heavy construction currently. The goal is to create a system that allows you to have "apps" that are installed on "accounts". It will also act as a switchboard for you to send signals to those apps based on what accounts they are installed on. Once I'm using this in production the dust should settle a little, but it's currently more of a proof of concept then stable platform.

## Usage

### Apps and Connections

Demux represents external applications as `Demux::App`s. Those apps can be connected to an account using a `Demux::Connection`. While demux leaves the presentation of these up to you and your app's UI, it gives you the tools that you need to support the installation process.

#### Demux::App

A `Demux::App` represents any external application that you want to be "installable" on an "account". It contains a `entry_url` that is used during the connecting of an app to an account.

#### Demux::Connection

A `Demux::Connection` ties a given `Demux::App` to an account. When you install an app on an account, you do that by creating a connection. How you do this will be up to you in our app, but you could likely have a simple controller action that creates a connection and then redirects to the entry_url.

The entry_url specifies where to redirect the user during the installation process so they can complete app specific configuration. After creating a connection, you can call `#entry_url` on it to get an entry URL with a signed JWT. Whatever URL is provided, we will add a `token` url param to that contains a signed JWT.

The JWT is signed using the "secret" for the connections app and contains the following payload:

```JSON
{
  "data": {"account_id": <some_id>},
  "exp":123455
}
```

The apps receiving the redirect to their URL should verify the JWT. It's signed using HS256. The app can use the account_id that was passed in the JWT to act on (create a new account, record, connection, whatever it needs to do at that point).

### Signals

Signals are messages that are sent to apps that are connected to an account in response to events that happen in that account. Demux acts like a switchboard making sure that any apps connected to the account where the event happened and that are listening for that signal will receive it.

#### Configuring an App for Signals

The url that a signal is sent to will be defined as the `signal_url` on your app when it's created.
An app has a `signals` column to contain the names of the signals that your app would like to receive when it's installed on an account. It's to use as a template when creating a new connection for what signals the connection should listen for.
A Connection also has a `signals` column and the signal names it contains will be used when resolving a signal to an app.

The reason they are in both places is to give the opportunity to ask for authorization from the client account for new signals the app is requesting to listen to. For example, if you add a "user" signal to your app you could then prompt that account to approve that app to now be able to listen for "user" signals. Once they give approval, you can add "user" to the signals list on the connection. If you don't desire an approvals process right now, you can just automatically update all the connections signals whenever a new signal is added to the app.

The signals column acts like an array, so you can add signals to an app like:

```Ruby
app = Demux::App.find(2)
app.signals << "user"
app.save
```
Here is an example of copying signals from an app to a new connection:

```Ruby
app = Demux::App.find(2)
Demux::Connection.create(account_id: 4, signals: app.signals)
```
Setting all existing connection to the signals of it's app:
```Ruby
app = Demux::App.find(2)
connection = app.connections.update_all(signals: app.signals)
```


#### Defining a Signal

Signals can live wherever you want as long as they are in your autoloaded paths; one recommendation would be to put them in an `app/signals/` directory.

Here is an example of defining a signal:

```Ruby
class LessonSignal < Demux::Signal
  attributes object_class: Lesson, signal_name: "lesson"

  def payload
    {
      company_id: lesson.company_id,
      lesson: {
        id: @object_id,
        name: lesson.name,
        public: lesson.public
      }
    }
  end

  def updated
    send :updated
  end

  def created_payload
    {
      company_id: lesson.company_id,
      lesson: {
        id: @object_id,
        name: lesson.name,
        created_at: lesson.created_at,
        public: lesson.public
      }
    }
  end

  def created
    send :created
  end

  private

  def lesson
    object
  end
end
```

You signal should inherit from `Demux::Signal`. It should also define the attributes of the signal using the `attributes` method. The `object_class` key should be the class of the "object" of the signal (it will be used to retrieve the object for the payload using the object_id like `object.find(object_id)`). `signal_name` is the name that will be used when resolving which apps are listening for this signal. It should be unique to this signal.

A signal can contain several actions. For example, if your app subscribes to the "lesson" signal you we receive all actions within that signal. In this signal, we have two actions defined, "updated" and "created". The only think you have to do in the action is call `send` with the name of the action (in the future, the plan is to allow you to give extra moment in time context that can be passed to the send call).

You can define a payload used by all actions, or for a specific action. When you define a method called "payload" this method will be used by all actions that don't have an action specific payload defined. If you wish, you can define an action specific payload by defining a method with the action name followed by `_payload`. As an example, see the create specific payload defined in the `create_payload` method in the example.

Inside the signal class, you will have access to the instance variable `@object_id` which represents the ID of the "object" of the signal (Lesson in this case). You also have access to `object` which will give you the initialized object for that ID. You can customize your signal further as you wish, for example in this signal we've created a private method to alias `object` as `lesson` and using that in our payload definitions.

#### Custom Demuxer

By default, the demuxer will resolve your signals inline. This is great for trying things out, but for performance you will likely want to do this asynchronously. Demux allows you to supply your own customized demuxer. A custom demuxer needs to respond to two methods, `#resolve` and `#transmit`. `#resolve` is called when a signal is sent with the SignalAttributes object, `#transmit` is called for each transmission object that is to be sent with that transmission as the argument.

This is what the default implementation of those methods look like:

```Ruby
module Demux
  class Demuxer
    def resolve
      resolve_now
    end

    def transmit(transmission)
      transmission.transmit
    end
  end
end
```

By default, resolve just calls `resolve_now` which synchronously resolves apps to the signal. Transmit just calls `#transmit` on the transmission to synchronously transmit it.

Lets say we want to create a demuxer that asynchronously resolve the signal and then asynchronously send each transmission individually. Here is an example of how you might implement that.

```Ruby
class AsyncDemuxer < Demux::Demuxer
  def resolve
    # Job to resolve signal. In that job we call #resolve_now
    DemuxResolverJob.perform(@signal_attributes)

    self
  end

  def transmit(transmission)
    # Calling transmit now creates a job in which we will call #transmit_now
    #   instead of transmitting synchronously
    DemuxTransmissionJob.perform(transmission.id)

    self
  end
end

class DemuxResolverJob
  def perform(signal_attributes)
    # Here is an example of calling `resolve_now` in the job
    AsyncDemuxer.new(signal_attributes).resolve_now
  end
end

class DemuxTransmissionJob
  def perform(transmission_id)
    Demux::Transmission.find(transmission_id).transmit
  end
end
```

We will configure Demux to use this demuxer in our initializer:

```Ruby
require "lib/async_demuxer"

Demux.configure do |config|
  config.default_demuxer = AsyncDemuxer
end
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'demux'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install demux
```

## Contributing
After cloning repo:

- install gems `bundle install`
- set up the databases `bundle exec rake db:setup`
- If you run into trouble setting up databases because of a missing postgres role, you can create one by running `psql` and then running `ALTER ROLE postgres LOGIN CREATEDB;`
- If you cannot start `psql` because you are missing a database named after your local user, you can create one using `createdb`
- You should not be able to run the tests `bundle exec rake`

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
