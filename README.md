# snapshots
An experiment of different snapshot implementations.

### Two streams snapshot repository
[source](two_streams)

- With dedicated stream for snapshot events
- Using Marshal for dumping an aggregate state
- Based on AggregateRoot::SnapshotRepository introduced in RailsEventStore in version 2.7 

### Single stream snapshot repository
[source](single_stream)

- Snapshot events mixed into aggregate's stream
- Applying Snapshot event explicitly like other event types


