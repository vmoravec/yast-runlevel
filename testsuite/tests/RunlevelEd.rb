# encoding: utf-8

module Yast
  class RunlevelEdClient < Client
    def main
      # testedfiles: RunlevelEd.ycp

      Yast.include self, "testsuite.rb"

      @READ = {
        "target"  => { "size" => 0 },
        "init"    => {
          "scripts" => {
            "runlevel_list"    => ["A", "B", "C", "1", "2", "5"],
            "current_runlevel" => "3"
          }
        },
        "process" => {
          # always report that process has exited already
          "running" => false,
          # process exited with return code 0
          "status"  => 0
        }
      }

      @WRITE = {}

      @EXECUTE = {
        "process" => {
          # returns PID
          "start_shell" => 1025,
          # ok, released
          "release"     => true
        },
        "target"  => {
          "bash_output" => { "exit" => 0, "stdout" => "OUT", "stderr" => "ERR" }
        }
      }

      TESTSUITE_INIT([@READ, @WRITE, @EXECUTE], nil)

      Yast.import "RunlevelEd"
      Yast.import "Assert"

      @separator = "---------------------------------"

      RunlevelEd.services = {
        "a" => {
          "reqstart" => ["a-1", "a-2", "d"],
          "start"    => ["B", "2", "3", "5"],
          "dirty"    => true
        },
        "b" => { "reqstart" => ["b-1", "b-2"], "start" => ["B"] },
        "c" => { "reqstart" => ["c-1", "c-2"], "start" => ["3", "5"] },
        # service required by "a"
        "d" => {
          "reqstart" => ["boot.test", "boot.local_test", "d-1"],
          "start"    => ["B", "5"],
          "dirty"    => true
        }
      }
      # Usually done in Read() function
      RunlevelEd.BuildServicesRequirements

      DUMP("SystemRunlevels")
      TEST(lambda { RunlevelEd.SystemRunlevels }, [@READ], nil)
      RunlevelEd.SetRunlevel4Support(true)
      TEST(lambda { RunlevelEd.SystemRunlevels }, [@READ], nil)
      DUMP(@separator)

      DUMP("ServicesDependencies")
      TEST(lambda { RunlevelEd.ServicesDependencies(["c", "a"]) }, [@READ], nil)
      DUMP(@separator)

      DUMP("RemoveDuplicates")
      DUMP(
        Assert.Equal(
          ["x", "a", "c", "b"],
          RunlevelEd.RemoveDuplicates(["x", "x", "a", "x", "c", "b", "a", "x"])
        )
      )
      DUMP(@separator)

      DUMP("GetCurrentRunlevel")
      TEST(lambda { RunlevelEd.GetCurrentRunlevel }, [@READ], nil)
      DUMP(@separator)

      DUMP("ListOfServicesToStart")
      # Returns only services that should be running in the current runlevel
      # and have been changed (dirty flag)
      TEST(lambda { RunlevelEd.ListOfServicesToStart }, [@READ, @WRITE, @EXECUTE], nil)
      DUMP(@separator)

      DUMP("StartServiceInRunlevels")
      # Should return [ "3", "5" ]
      TEST(lambda { RunlevelEd.StartServiceInRunlevels("c") }, [
        @READ,
        @WRITE,
        @EXECUTE
      ], nil)
      DUMP(@separator)

      DUMP("StartServicesWithDependencies")
      TEST(lambda { RunlevelEd.StartServicesWithDependencies(["a", "b"]) }, [
        @READ,
        @WRITE,
        @EXECUTE
      ], nil)
      DUMP(@separator)

      DUMP("AdaptServices")
      TEST(lambda { RunlevelEd.AdaptServices(RunlevelEd.services, false) }, [
        @READ,
        @WRITE,
        @EXECUTE
      ], nil)
      DUMP(@separator)

      DUMP("EnableServices")
      TEST(lambda { RunlevelEd.EnableServices(["a", "b", "d"]) }, [
        @READ,
        @WRITE,
        @EXECUTE
      ], nil)
      DUMP(@separator)

      nil
    end
  end
end

Yast::RunlevelEdClient.new.main
