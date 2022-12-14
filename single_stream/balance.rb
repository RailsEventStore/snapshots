require "aggregate_root"
require "ruby_event_store/event"

class Balance
  include AggregateRoot

  Credited = Class.new(RubyEventStore::Event)
  Withdrawn = Class.new(RubyEventStore::Event)
  Snapshot = Class.new(RubyEventStore::Event)

  InsufficientFunds = Class.new(StandardError)

  def initialize
    @amount = 0
  end

  def credit(amount)
    apply(Credited.new(data: { amount: amount }))
  end

  def withdraw(amount)
    raise InsufficientFunds if @amount < amount

    apply(Withdrawn.new(data: { amount: amount }))
  end

  def __snapshot_event__
    Snapshot.new(data: { amount: @amount, version: @version })
  end

  on Credited do |event|
    @amount += event.data[:amount]
  end

  on Withdrawn do |event|
    @amount -= event.data[:amount]
  end

  on Snapshot do |event|
    @amount = event.data[:amount]
    @version = event.data[:version]
  end
end
