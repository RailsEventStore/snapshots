require "ruby_event_store"
require "minitest/autorun"

$res = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)

class BalanceTest < Minitest::Test 
  def balance(&block)
    AggregateRoot::SnapshotRepository.new($res).with_aggregate(Balance.new, "balance", &block)
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

