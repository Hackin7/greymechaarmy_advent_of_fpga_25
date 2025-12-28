open! Core
open! Hardcaml
open! Signal








(* ================================================================================ *)
(* === Interface                                                                === *)
(* ================================================================================ *)

let width_interface = 16*8
let width_compute   = 32
let num_bits = width_interface

(* Every hardcaml module should have an I and an O record, which define the module
   interface. *)
module I = struct
  type 'a t =
    { clk       : 'a
    ; rst       : 'a
    ; din       : 'a [@bits width_interface]
    ; din_valid : 'a
    ; control   : 'a [@bits 5]
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { 
      dout       : 'a [@bits width_interface]
      ;dout_valid : 'a 
    }
  [@@deriving hardcaml]
end











(* ================================================================================ *)
(* === Functionality                                                            === *)
(* ================================================================================ *)


module States = struct
  type t =
    | Idle
    | Computing
    | Done
  [@@deriving sexp_of, compare ~localize, enumerate]
end

let create scope ({ clk; rst; control; din; din_valid } : _ I.t) : _ O.t
  =
  (* --- Initialisation -------------------------------------------------------- *)
  let spec = Reg_spec.create ~clock:clk ~clear:rst () in
  (* --- "Stage" 1: Data Input (to reduce crit path length) -------------------- *)
  let din_full_dly  = Signal.reg spec ~enable:Signal.vdd din in
  let din_valid_dly = Signal.reg spec ~enable:Signal.vdd din_valid in

  let din_dly       = (uresize din_full_dly ~width:width_compute) in

  (* --- "Stage" 2: Calc position ---------------------------------------------- *)
  let spec_pos = Reg_spec.create ~clock:clk () in
  let open Always in (* Like from Always import * *)
  let sm =
    (* Note that the state machine defaults to initializing to the first state *)
    State_machine.create (module States) spec
  in

  (* let%hw[_var] is a shorthand that automatically applies a name to the signal, which
    will show up in waveforms. The [_var] version is used when working with the Always
    DSL. *)
  let%hw_var calc_position               = Variable.reg spec_pos  ~width:width_compute in
  let calc_position_is_neg               = (select calc_position.value ~high:31 ~low:31) in
  let%hw_var calc_position_was_zero      = Variable.reg spec  ~width:1 in
  let%hw_var calc_prev_computing_ptive   = Variable.reg spec  ~width:1 in
  let%hw_var calc_num_loops_a            = Variable.reg spec  ~width:width_compute in
  let%hw_var calc_num_loops_b            = Variable.reg spec  ~width:width_compute in
  

  (* Modulo and count logic *)
  compile
    [ sm.switch
        [ 
          ( Idle,
          [ 
              when_ (rst) [
                calc_position <--. 50;
              ];
              when_ (din_valid_dly) [ 
                  calc_position <-- (calc_position.value +: din_dly); 
                  calc_position_was_zero <-- (calc_position.value ==:. 0);
                  calc_prev_computing_ptive <--. 0;
                  sm.set_next Computing;
              ]
            ] 
          );(Computing, [ 
              when_ (calc_position_is_neg) [
                when_ (calc_position.value <=: Signal.of_int_trunc ~width:width_compute (-100)) [
                  calc_num_loops_b <-- (calc_num_loops_b.value +:. 1);
                ];
                when_ (calc_position.value >: Signal.of_int_trunc ~width:width_compute (-100)) [
                  calc_num_loops_b <-- (
                    calc_num_loops_b.value +: 
                    (uresize (~: (calc_position_was_zero.value)) ~width:width_compute)
                  );
                ];
                calc_position <-- (calc_position.value +:. 100);
              ];
              when_ (calc_position.value >=:. 100) [when_ (~: calc_position_is_neg) [
                calc_prev_computing_ptive <--. 1;
                calc_position    <-- (calc_position.value -:. 100);
                calc_num_loops_b <-- (calc_num_loops_b.value +:. 1);
              ];];
              when_ (calc_position.value <:. 100) [when_ (calc_position.value >=:. 0) [
                calc_num_loops_b <-- (
                  calc_num_loops_b.value +: 
                  (uresize (calc_position.value ==:. 0) ~width:width_compute)
                );
                sm.set_next Done;
              ];];
          ]);( Done, [
            calc_num_loops_a <-- calc_num_loops_a.value +:. 1;
            sm.set_next Idle
          ])
        ]
    ];

  (* let dout_valid = Signal.reg _spec ~enable:Signal.vdd din_valid in *)
  
  (* --- "Stage" 3: Calc count -------------------------------------------------- *)
  let calc_count_next      = Signal.wire width_compute in
  let calc_count           = Signal.reg spec ~enable:Signal.vdd calc_count_next in
  let () =  Signal.assign calc_count_next Signal.(
    calc_count +: (uresize din_dly ~width:width_compute)
  ) in

  (* --- Output -------------------------------------------------------- *)
  (* [.value] is used to get the underlying Signal.t from a Variable.t in the Always DSL. *)

  let enable_part_b = select control ~high:3 ~low:3 in

  let dout  = Signal.concat_msb [
    (uresize Signal.gnd ~width:(width_interface-width_compute)); 
    (Signal.mux2 enable_part_b calc_num_loops_b.value calc_num_loops_a.value)
  ] in
  (* let dout_valid = Signal.vdd in *)
  let dout_valid = calc_prev_computing_ptive.value in

  { dout = dout ; dout_valid = dout_valid }
;;

(* The [hierarchical] wrapper is used to maintain module hierarchy in the generated
   waveforms and (optionally) the generated RTL. *)
let hierarchical scope =
  let module Scoped = Hierarchy.In_scope (I) (O) in
  Scoped.hierarchical ~scope ~name:"coprocessor" create
;;