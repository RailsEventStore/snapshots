# frozen_string_literal: true
require 'base64'

module AggregateRoot
  class TwoStreamsSnapshotRepository
    def initialize(event_store, interval = 1)
      @event_store = event_store
      @interval = interval
    end

    SnapshotEvent = Class.new(RubyEventStore::Event)

    def load(aggregate, stream_name)
      last_snapshot = load_snapshot_event(stream_name)
      query = event_store.read.stream(stream_name)
      if last_snapshot
        aggregate = load_marshal(last_snapshot)
        query = query.from(last_snapshot.data[:last_event_id])
      end
      query.reduce { |_, ev| aggregate.apply(ev) }
      aggregate.version = aggregate.version + aggregate.unpublished_events.count
      aggregate
    end

    def store(aggregate, stream_name)
      events = aggregate.unpublished_events.to_a
      event_store.publish(events,
                          stream_name: stream_name,
                          expected_version: aggregate.version)

      aggregate.version = aggregate.version + events.count

      if time_for_snapshot?(aggregate.version)
        publish_snapshot_event(aggregate, stream_name, events.last.event_id)
      end
    end

    def with_aggregate(aggregate, stream_name, &block)
      aggregate = load(aggregate, stream_name)
      block.call(aggregate)
      store(aggregate, stream_name)
    end

    private

    attr_reader :event_store, :interval

    def publish_snapshot_event(aggregate, stream_name, last_event_id)
      event_store.publish(
        SnapshotEvent.new(data: { marshal: build_marshal(aggregate), last_event_id: last_event_id }),
        stream_name: snapshot_stream_name(stream_name)
      )
    end

    def build_marshal(aggregate)
      Base64.encode64(Marshal.dump(aggregate))
    end

    def load_snapshot_event(stream_name)
      event_store.read.stream(snapshot_stream_name(stream_name)).last
    end

    def load_marshal(snpashot_event)
      Marshal.load(Base64.decode64(snpashot_event.data[:marshal]))
    end

    def snapshot_stream_name(stream_name)
      "#{stream_name}_snapshots"
    end

    def time_for_snapshot?(version)
      version % interval == 0
    end
  end
end