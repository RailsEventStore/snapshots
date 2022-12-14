test_single_stream:
	@bundle exec ruby -Isingle_stream -rsnapshot_repository -rbalance balance_test.rb
test_two_streams:
	@bundle exec ruby -Itwo_streams -rsnapshot_repository -rbalance balance_test.rb