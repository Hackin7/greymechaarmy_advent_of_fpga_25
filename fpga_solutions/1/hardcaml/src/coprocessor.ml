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

let create scope ({ clk; rst; control = _; din; din_valid } : _ I.t) : _ O.t
  =
  (* --- Initialisation -------------------------------------------------------- *)
  let spec = Reg_spec.create ~clock:clk ~clear:rst () in
  let spec_position = Reg_spec.create ~clock:clk ~clear:rst() in


  (* --- "Stage" 1: Data Input (to reduce crit path length) -------------------- *)
  let din_dly  = Signal.reg spec ~enable:Signal.vdd din in
  let din_valid_dly = Signal.reg spec ~enable:Signal.vdd din_valid in
  
  

  (* --- "Stage" 2: Calc position ---------------------------------------------- *)
  let calc_position_next      = Signal.wire width_compute in
  let calc_position           = Signal.reg spec_position ~enable:Signal.vdd calc_position_next in
  let () =  Signal.assign calc_position_next Signal.(calc_position +: (uresize din_dly ~width:width_compute)) in

  (* let calc_position_was_zero  = Signal.reg _spec ~enable:Signal.vdd din in
  let calc_final_position     = Signal.reg _spec ~enable:Signal.vdd din in

  let calc_position_state     = Signal.reg _spec ~enable:Signal.vdd din in
  let calc_prev_computing     = Signal.reg _spec ~enable:Signal.vdd din in *)


  let open Always in
  let sm =
    (* Note that the state machine defaults to initializing to the first state *)
    State_machine.create (module States) spec
  in

  (* let%hw[_var] is a shorthand that automatically applies a name to the signal, which
    will show up in waveforms. The [_var] version is used when working with the Always
    DSL. *)
  let%hw_var ultimate_val = Variable.reg spec  ~width:width_compute in

  compile
    [ sm.switch
        [ ( Idle
          , [ when_
                din_valid_dly
                [ 
                    ultimate_val <-- zero width_compute
                  ; sm.set_next Computing
                ]
            ] )
        ; ( Computing
          , [ 
              (* ultimate_val <-- din_dly;  *)
              sm.set_next Done 
            ] )
        ; ( Done
          , [sm.set_next Computing] )
        ]
    ];

  (* let dout_valid = Signal.reg _spec ~enable:Signal.vdd din_valid in *)

  let _din_compute = Signal.select din ~high:31 ~low:0  in (* 32 bit computation *)
  
  
  (* --- "Stage" 3: Calc count -------------------------------------------------- *)

  (* --- Output -------------------------------------------------------- *)
  let dout  = Signal.concat_msb [
    (uresize Signal.gnd ~width:(width_interface-width_compute)); 
    ultimate_val.value
  ] in
  let dout_valid = Signal.vdd in

  { dout = dout ; dout_valid = dout_valid }
;;

(* The [hierarchical] wrapper is used to maintain module hierarchy in the generated
   waveforms and (optionally) the generated RTL. *)
let hierarchical scope =
  let module Scoped = Hierarchy.In_scope (I) (O) in
  Scoped.hierarchical ~scope ~name:"coprocessor" create
;;
