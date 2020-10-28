[![Build Status](https://travis-ci.com/lessonly/demux.svg?branch=master)](https://travis-ci.com/lessonly/demux)
[![Inline docs](http://inch-ci.org/github/lessonly/demux.svg?branch=master)](http://inch-ci.org/github/lessonly/demux)
[![Maintainability](https://api.codeclimate.com/v1/badges/c614855285e9c43f198d/maintainability)](https://codeclimate.com/github/lessonly/demux/maintainability)

# Demux

Demux is under heavy construction currently. The goal is to create a system that allows you to have "apps" that are installed on "accounts". It will also act as a switchboard for you to send signals to those apps based on what accounts they are installed on. Once I'm using this in production the dust should settle a little, but it's currently more of a proof of concept then stable platform.

## Usage

### Apps and Connections

Demux represents external applications as `Demux::App`s. Those apps can be connected to an account using a `Demux::Connection`. While demux leaves the presentation of these up to you and your app's UI, it gives you the tools that you need to support the installation process.

#### Demux::App

A `Demux::App` represents any external application that you want to be "installable" on an "account". It contains a `entry_url` that is used during the connecting of an app to an account.

#### Demux::Connection

A `Demux::Connection` ties a given `Demux::App` to an account. When you install an app on an account, you do that by creating a connection. How you do this will be up to you in your host app, but you could likely have a simple controller action that creates a connection and then redirects to the entry_url. Here is a basic example for installing and configuring connections. It includes no authorization which should be considered for a production app.
```Ruby
class ConnectionsController < ApplicationController
  # Create action for installing an app by creating a connection
  def create
    app = Demux::App.find(params[:app_id])

    connection = app.connections.find_or_initialize_by(
      account_id: current_account.id,
      signals: app.signals
    )

    connection.save! if connection.new_record?

    redirect_to connection.entry_url
  end

  # Configuring an existing connection between an app and an account
  def show
    connection = Demux::Connection.find(params[:id])

    redirect_to connection.entry_url
  end
end
```

The entry_url specifies where to redirect the user during the installation process so they can complete app specific configuration. After creating a connection, you can call `#entry_url` on it to get an entry URL with a signed JWT. Whatever URL is provided, we will add a `token` url param to that contains a signed JWT.

The JWT is signed using the "secret" for the connections app and contains the following payload:

```JSON
{
  "data": {"account_id": <some_id>},
  "exp":123455
}
```

The apps receiving the redirect to their URL should verify the JWT. It's signed using HS256. The app can use the account_id that was passed in the JWT to act on (create a new account, record, connection, whatever it needs to do at that point).

If needed for your use case, extra data can be included in the entry_url payload when it's build. For example, you could include a user_id.

```Ruby
connection.entry_url(data: { user_id: 42 })
```
Resulting in a payload like:
```JSON
{
  "data": {"account_id": <some_id>, user_id: 42},
  "exp":123455
}
```

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

Inside the signal class, you will have access to the method `object_id` which represents the ID of the "object" of the signal (Lesson in this case). You also have access to `object` which will give you the initialized object for that ID. You can customize your signal further as you wish, for example in this signal we've created a private method to alias `object` as `lesson` and using that in our payload definitions. You also have access to the `context` method to access any context passed when the signal is sent.

#### Signal Context

Sometimes you'll have context for a signal that is perishable and cannot be retrieved from the database later before sending the signal. The payload methods in the signal are called only when sending a signal and will capture the state of the object at that point; context gives you a way to capture state now in an eager way. Here is an example of a signal using context:

```Ruby
class LessonSignal < Demux::Signal
  attributes object_class: Lesson, signal_name: "lesson"

  def destroyed_payload
    {
      company_id: account_id,
      **context
    }
  end

  def destroyed
    send :destroyed, context: destroyed_context
  end

  private

  def lesson
    object
  end

  def destroyed_context
    {
      lesson: {
        id: lesson.id,
        name: lesson.name,
        public: lesson.public
      }
    }
  end
end
```

Call this signal with a lesson object like: `LessonSignal.new(lesson, account_id: 9).destroyed`

In this case, we are using context to store information on an object that has been supplied to the signal and that won't be available later (because it was destroyed). We supply the lesson object for us to pull data from instead of just an ID because this object is no longer in the database and we can retrieve it later using an ID. A private method is used to structure that context here, but its just plain old ruby so feel free to structure that how you think is best; there is nothing special about this private method.

When building the payload, we'll have access to the context by calling `context` so that we can build it into the payload that will be delivered with the signal. Here we are just using a double splat to expand the context hash in it's entirety into the payload. You could also be more explicit like:

```Ruby
def destroyed_payload
  context_lesson = context[:lesson]
  {
    company_id: account_id,
    lesson: {
      name: context_lesson[:name],
      public: context_lesson[:public]
    }
  }
end
```

The second way has the advantage of making the structure of the payload clearer, even if it is more verbose. Once again, its plain ol' Ruby so that's up to you!

Another way that context can be used is to add perishable data at the time the signal is called in addition to the object data that is retrieved later. An example of this might be adding the id of the archiver when archiving an object. We will not know the ID of the archiver later if it is specific to the context in which the signal is called (unless it's save in the DB of course, but lets assume its not here).

```Ruby
class LessonSignal < Demux::Signal
  attributes object_class: Lesson, signal_name: "lesson"

  def archival_payload
    {
      company_id: account_id,
      lesson: {
        id: object.id,
        name: lesson.name,
        public: lesson.public
      },
      archivist_id: context[:archivist_id]
    }
  end

  def archival(archivist_id:)
    send :archival, context: { archivist_id: archivist_id }
  end

  private

  def lesson
    object
  end
```

Here, we are accepting an argument into our action that we use to form a context we pass along with the call to send the signal. We then use it in the payload to add the archivist_id.

One thing to note about adding context to a signal is that the context is factored into the "uniqueness" of a signal. If two signals are triggered with the same parameters but different values in their context, they are not considered the same and both signals will be sent. That is because the context is perishable; if the same signal happens more than once but with different context we would lose that context if we collapsed the two signals into one. As a practical example, let's take the example of the archival signal above. The following two signal calls would be considered unique and will not be de-duplicated:

```Ruby
LessonSignal.new(4, account_id: 9).archival(archivist_id: 3)
LessonSignal.new(4, account_id: 9).archival(archivist_id: 8)
```

#### Initializing a Signal

As shown in the examples above, there are two ways you can initialize a signal and you'll want to be aware of the difference and when to use one over the other. You can initialize a signal with the ID of an object to retrieve later from the database `LessonSignal.new(4, account_id: 9)` or you can initialize with the instance of an object `LessonSignal.new(lesson, account_id: 9)`.

When you initialize with just an ID, this ID will be used to retrieve a model from the database with the type set in `object_type` for the signal. So in this examples case, it will try to find a `Lesson` with the ID of 4. This allows us to build a payload asynchronously in the case that we can pull the object from the DB. It also allows us to get and send only the latest version of the object when sending the signal (not just the state when the signal was called).

You can also initialize using the instance of an object. If the object responds to ID, that ID will be saved to make a lookup possible later. It's also possible though that you will have an object that cannot be retrieved later, like in the `destroyed` example above. In this case, passing the object in allows us to form a context from it to pass along with send in that moment instead of later when the signal is being sent.

Which is better depends on what you need for that action. Be aware though, if you don't use an ID or an object that responds to ID and that is accessible later you will not be able to use that object in the payload (only in a context).

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
    DemuxResolverJob.perform(demuxer_arguments)

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
  def perform(demuxer_arguments)
    # Here is an example of calling `resolve_now` in the job
    AsyncDemuxer.new(**demuxer_arguments).resolve_now
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

#### Purging Old Signals

Since we are creating new transmissions all the time, the demux_transmissions table has the potential to get very large. You will very likely want to set up a job to purge old transmissions periodically. For this you can use the `Demux::Transmission#purge` method and call it using the task scheduling method of your choosing. For example, you could set up a job that runs every night and purges transmissions older than a month using the following call:

```Ruby
Demux::Transmissions.purge(older_than: 1.month.ago)
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
Please consider starting a conversation in an issue before putting time into a PR to make sure the change tracks with the vision for the project.

After cloning repo:

- install gems `bundle install`
- set up the databases `bundle exec rake db:setup`
- If you run into trouble setting up databases because of a missing postgres role, you can create one by running `psql` and then running `ALTER ROLE postgres LOGIN CREATEDB;`
- If you cannot start `psql` because you are missing a database named after your local user, you can create one using `createdb`
- You should not be able to run the tests `bundle exec rake`

Please squash the code in your PR down into a commit with a sensible message before requesting review (or after making updates based on review).

Here are some tips on good commit messages:
[Thoughtbot](https://thoughtbot.com/blog/5-useful-tips-for-a-better-commit-message)
[Tim Pope](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)

## Current Maintainers

- Ross @rreinhardt9

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
