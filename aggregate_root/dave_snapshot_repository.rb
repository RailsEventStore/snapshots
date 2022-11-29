# frozen_string_literal: true

module AggregateRoot
  class SnapshotRepository
    def initialize(event_store, interval = 2)
      @event_store = event_store
      @interval = interval
    end

    def load(aggregate, stream_name)
      snapshot = event_store.read
                            .stream(stream_name)
                            .of_type(aggregate.__snapshot_event__.event_type)
                            .last

      if snapshot
        aggregate.apply(snapshot)
        event_store.read
                   .stream(stream_name)
                   .from(snapshot.event_id)
                   .reduce { |_, event| aggregate.apply(event) }

        aggregate.version = snapshot.version + aggregate.unpublished_events.count
      else
        event_store.read
                   .stream(stream_name)
                   .reduce { |_, event| aggregate.apply(event) }

        aggregate.version = aggregate.unpublished_events.count - 1
      end

      aggregate
    end

    def store(aggregate, stream_name)
      events = aggregate.unpublished_events.to_a
      events << aggregate.__snapshot_event__ if snapshot_time(events, stream_name)

      event_store.publish(
        events,
        stream_name: stream_name,
        expected_version: aggregate.version
      )

      aggregate.version = aggregate.version + events.count
    end

    private

    attr_reader :event_store, :interval

    def snapshot_time(events, stream_name)
      total_event_count = event_store.read.stream(stream_name).count + events.size
      return false unless total_event_count >= interval
      (total_event_count % interval).zero?
    end
  end
end