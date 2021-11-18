#!/usr/bin/wish

# This file provides shell command procedures cmd_fnc and t_cmd_fnc.

my_source [list print.tcl]


proc cmd_fnc { cmd_buf { quiet {} } { test_mode {} } { print_output {} }\
  { show_err {} } { ignore_err {} } { acceptable_shell_rcs {} } } {

  # Run the given command in a shell and return the shell return code and the output as a 2 element list.

  # Example usage:
  # set result [cmd_fnc "date"].

  # Example output:

  # #(CST) 2018/01/17 16:23:28.951643 -    0.001086 - Issuing: date
  # Mon Feb 19 10:12:10 CST 2018
  # result:
  #   result[0]:                                      0x00000000
  #   result[1]:                                      Mon Feb 19 10:12:10 CST 2018

  # Note: Because of the way this procedure processes parms, the user can specify blank values as a way of
  # skipping parms.  In the following example, the caller is indicating that they wish to have quiet and
  # test_mode take their normal defaults but have print_output be 0.:
  # cmd_fnc "date" "" "" 0

  # Description of argument(s):
  # cmd_buf                         The command string to be run in a shell.
  # quiet                           Indicates whether this procedure should run the print_issuing() procedure
  #                                 which prints "Issuing: <cmd string>" to stdout.  The default value is 0.
  # test_mode                       If test_mode is set, this procedure will not actually run the command.
  #                                 If print_output is set, it will print "(test_mode) Issuing: <cmd string>"
  #                                 to stdout.  The default value is 0.
  # print_output                    If this is set, this procedure will print the stdout/stderr generated by
  #                                 the shell command.  The default value is 1.
  # show_err                        If show_err is set, this procedure will print a standardized error report
  #                                 if the shell command returns non-zero.  The default value is 1.
  # ignore_err                      If ignore_err is set, this procedure will not fail if the shell command
  #                                 fails.  However, if ignore_err is not set, this procedure will exit 1 if
  #                                 the shell command fails.  The default value is 1.
  # acceptable_shell_rcs            A list of acceptable shell rcs.  If the shell return code is found in
  #                                 this list, the shell command is considered successful.  The default value
  #                                 is {0}.

  # Set defaults.
  set_var_default quiet [get_stack_var quiet 0 2]
  set_var_default test_mode 0
  set_var_default print_output 1
  set_var_default show_err 1
  set_var_default ignore_err 1
  set_var_default acceptable_shell_rcs 0

  qpissuing $cmd_buf $test_mode

  if { $test_mode } { return [list 0 ""] }

  set shell_rc 0

  if { [ catch {set out_buf [eval exec bash -c {$cmd_buf}]} result ] } {
    set out_buf $result
    set shell_rc [lindex $::errorCode 2]
  }

  if { $print_output } { puts "${out_buf}" }

  # Check whether return code is acceptable.
  if { [lsearch -exact $acceptable_shell_rcs ${shell_rc}] == -1 } {
    # The command failed.
    append error_message "The prior shell command failed.\n"
    append error_message [sprint_var shell_rc "" "" 1]
    if { $acceptable_shell_rcs != 0 } {
      # acceptable_shell_rcs contains more than just a single element equal to 0.
      append error_message "\n"
      append error_message [sprint_list acceptable_shell_rcs "" "" 1]
    }
    if { ! $print_output } {
      append error_message "out_buf:\n${out_buf}"
    }
    if { $show_err } {
      print_error_report $error_message
    }

    if { ! $ignore_err } {
      exit 1
    }

  }

  return [list $shell_rc $out_buf]

}


proc t_cmd_fnc { args } {

  # Call cmd_fnc with test_mode equal to the test_mode setting found by searching up the call stack.  See
  # cmd_fnc (above) for details for all other arguments.

  # We wish to obtain a value for test_mode by searching up the call stack.  This value will govern whether
  # the command specified actually gets executed.
  set_var_default test_mode [get_stack_var test_mode 0 2]

  # Since we wish to manipulate the value of test_mode, which is the third positional parm, we must make
  # sure we have at least 3 parms.  We will now append blank values to the args list as needed to ensure that
  # we have the minimum 3 parms.
  set min_args 3
  for {set ix [llength $args]} {$ix < $min_args} {incr ix} {
    lappend args {}
  }

  # Now replace the caller's test_mode value with the value obtained from the call stack search.  It does
  # not matter what value is specified by the caller for test_mode.  It will be replaced.  The whole point of
  # calling t_cmd_fnc is to allow it to set the test_mode.
  set args [lreplace $args 2 2 $test_mode]

  return [cmd_fnc {*}$args]

}