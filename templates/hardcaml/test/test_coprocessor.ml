open! Core
open! Hardcaml
open! Hardcaml_waveterm
open! Hardcaml_test_harness
module Coprocessor = Hardcaml_demo_project.Coprocessor
module Harness = Cyclesim_harness.Make (Coprocessor.I) (Coprocessor.O)

let ( <--. ) = Bits.( <--. )
let sample_input_values = [ 255; 67; 150; 4 ]

let simple_testbench (sim : Harness.Sim.t) =
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in
  let cycle ?n () = Cyclesim.cycle ?n sim in
  
  (* --- Reset the design ----------------------------------- *)
  inputs.rst := Bits.vdd;
  cycle ();
  inputs.rst := Bits.gnd;
  cycle ();

  (* --- Input some data ------------------------------------ *)

  (* Helper function for inputting one value *)
  let feed_input n =
    inputs.din <--. n;
    (* inputs.din_valid := Bits.vdd;
    cycle (); *)
    inputs.din_valid := Bits.gnd;
    cycle ()
  in

  List.iter sample_input_values ~f:(fun x -> feed_input x);
  inputs.din_valid := Bits.vdd;
  cycle ();
  
  (* --- Wait for result to become valid -------------------- *)
  while not (Bits.to_bool !(outputs.dout_valid)) do
    cycle ()
  done;
  let range = Bits.to_unsigned_int !(outputs.dout) in
  print_s [%message "Result" (range : int)];

  (* --- Show in the waveform that [valid] stays high. ------ *)
  cycle ~n:2 ()
;;


(* ============================================================================================ *)
(* === Exporting Waveform                                                                   === *)
(* ============================================================================================ *)

(* The [waves_config] argument to [Harness.run] determines where and how to save waveforms
   for viewing later with a waveform viewer. The commented examples below show how to save
   a waveterm file or a VCD file. *)
(* let waves_config = Waves_config.no_waves;; *)

let waves_config =
  Waves_config.to_directory "/tmp/"
  (* |> Waves_config.as_wavefile_format ~format:Hardcamlwaveform *)
  |> Waves_config.as_wavefile_format ~format:Vcd
;;

(* let waves_config =  *)
  (* Waves_config.to_directory "/tmp/" *)
  (* |> Waves_config.as_wavefile_format ~format:Vcd *)
(* ;; *)


(* ============================================================================================ *)
(* === Expected Tests & Checks                                                              === *)
(* ============================================================================================ *)

let%expect_test "Simple test, optionally saving waveforms to disk" =
  Harness.run_advanced ~waves_config ~create:Coprocessor.hierarchical simple_testbench;
  [%expect {| (Result (range 154)) |}]
;;
(* 
let%expect_test "Simple test with printing waveforms directly" =
  (* For simple tests, we can print the waveforms directly in an expect-test (and use the
     command [dune promote] to update it after the tests run). This is useful for quickly
     visualizing or documenting a simple circuit, but limits the amount of data that can
     be shown. *)
  let display_rules =
    [ Display_rule.port_name_matches
        ~wave_format:(Bit_or Unsigned_int)
        (Re.Glob.glob "coprocessor*" |> Re.compile)
    ]
  in
  Harness.run_advanced
    ~create:Coprocessor.hierarchical
    ~trace:`All_named
    ~print_waves_after_test:(fun waves ->
      Waveform.print
        ~display_rules
          (* [display_rules] is optional, if not specified, it will print all named
             signals in the design. *)
        ~signals_width:30
        ~display_width:92
        ~wave_width:1
        (* [wave_width] configures how many chars wide each clock cycle is *)
        waves)
    simple_testbench;
;; *)
