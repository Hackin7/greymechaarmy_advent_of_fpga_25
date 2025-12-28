open! Core
open! Hardcaml
open! Signal








(* ================================================================================ *)
(* === Interface                                                                === *)
(* ================================================================================ *)

let num_bits = 16*8q

(* Every hardcaml module should have an I and an O record, which define the module
   interface. *)
module I = struct
  type 'a t =
    { clk       : 'a
    ; rst       : 'a
    ; din       : 'a [@bits num_bits]
    ; din_valid : 'a
    ; control   : 'a [@bits 5]
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { 
      dout       : 'a [@bits num_bits]
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
    | Accepting_inputs
    | Done
  [@@deriving sexp_of, compare ~localize, enumerate]
end

let create _scope ({ clk; rst; control = _; din; din_valid } : _ I.t) : _ O.t
  =
  (* --- Initialisation -------------------------------------------------------- *)
  let _spec = Reg_spec.create ~clock:clk ~clear:rst () in
  let dout  = Signal.reg _spec ~enable:Signal.vdd din in
  let dout_valid = Signal.reg _spec ~enable:Signal.vdd din_valid in

  let _din_compute = Signal.select din ~high:31 ~low:0  in (* 32 bit computation *)
  
  (* --- Output -------------------------------------------------------- *)
  { dout = dout ; dout_valid = dout_valid }
;;

(* The [hierarchical] wrapper is used to maintain module hierarchy in the generated
   waveforms and (optionally) the generated RTL. *)
let hierarchical scope =
  let module Scoped = Hierarchy.In_scope (I) (O) in
  Scoped.hierarchical ~scope ~name:"coprocessor" create
;;
