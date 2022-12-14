# frozen_string_literal: true

module AggregateRoot
  class SnapshotRepository
    def initialize(event_store, interval = 2)
      @event_store = event_store
      @interval = interval
    end

    def load(aggregate, stream_name)
      events_query = event_store.read.stream(stream_name)
      snapshot = events_query.of_type(aggregate.__snapshot_event__.event_type).last
      if snapshot
        aggregate.apply(snapshot)
        aggregate.version = events_query.to(snapshot.event_id).count
        events_query = events_query.from(snapshot.event_id)
      end
      events_query.reduce { |_, event| aggregate.apply(event) }
      aggregate.version = aggregate.version + aggregate.unpublished_events.count
      aggregate
    end

    def store(aggregate, stream_name)
      events = aggregate.unpublished_events.to_a
      events << aggregate.__snapshot_event__ if time_for_snapshot?(aggregate.version, events.size)
      event_store.publish(
        events,
        stream_name: stream_name,
        expected_version: aggregate.version
      )
      aggregate.version = aggregate.version + events.count
    end

    def with_aggregate(aggregate, stream_name, &block)
      block.call(load(aggregate, stream_name))
      store(aggregate, stream_name)
    end

    private

    attr_reader :event_store, :interval

    def time_for_snapshot?(aggregate_version, just_published_events)
      events_in_stream = aggregate_version + 1
      events_since_time_for_snapshot = events_in_stream % interval
      just_published_events > events_since_time_for_snapshot
    end
  end
end