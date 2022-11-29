require "ruby_event_store"
require "aggregate_root"
require "minitest/autorun"
require_relative "aggregate_root/two_streams_snapshot_repository"


$res = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)

class Balance
  include AggregateRoot 

  Credited  = Class.new(RubyEventStore::Event)
  Withdrawn = Class.new(RubyEventStore::Event)

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

  on Credited do |event|
    @amount += event.data[:amount]
  end

  on Withdrawn do |event|
    @amount -= event.data[:amount]
  end
end

class BalanceTest < Minitest::Test 
  def balance(&block)
    AggregateRoot::TwoStreamsSnapshotRepository.new($res).with_aggregate(Balance.new, "balance", &block)
  end

  def test_happy
    balance do |b| 
      b.credit(100) 
      b.credit(100) 
      b.credit(100) 
      b.credit(100) 
      b.credit(100) 
    end
    balance { |b| b.withdraw(500) }
  end

  def test_fail
    assert_raises Balance::InsufficientFunds do
      balance { |b| b.withdraw(500) }
    end
  end
end

