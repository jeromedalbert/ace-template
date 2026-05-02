# Make minitest-reporters work with latest Minitest version while waiting for
# https://github.com/minitest-reporters/minitest-reporters/pull/366
# to be addressed.
require 'minitest/minitest_reporter_plugin'
Minitest.register_plugin :minitest_reporter
