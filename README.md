# snapshots
An experiment of different snapshot implementations.

### Two streams snapshot repository
[source](two_streams)

- With dedicated stream for snapshot events
- Using Marshal for dumping an aggregate state
- Based on AggregateRoot::SnapshotRepository introduced in RailsEventStore in version 2.7

<img src="https://user-images.githubusercontent.com/9444951/207668081-78d33e67-4e17-4189-a9c8-e0fa5402cbcb.png" height="600">

### Single stream snapshot repository
[source](single_stream)

- Snapshot events mixed into aggregate's stream
- Applying Snapshot event explicitly like other event types

<img src="https://user-images.githubusercontent.com/9444951/207668106-00dec97d-3865-4c14-9a81-980b65a53d7d.png" height="600">


