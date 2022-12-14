require "aggregate_root"
require "ruby_event_store/event"

class Balance
  include AggregateRoot

  Credited = Class.new(RubyEventStore::Event)
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

  UNMARSHALED_VARIABLES = [:@version, :@unpublished_events]

  def marshal_dump
    instance_variables.reject{|m| UNMARSHALED_VARIABLES.include? m}.inject({}) do |vars, attr|
      vars[attr] = instance_variable_get(attr)
      vars
    end
  end

  def marshal_load(vars)
    vars.each do |attr, value|
      instance_variable_set(attr, value) unless UNMARSHALED_VARIABLES.include?(attr)
    end
  end
end
