(** Copyright 2021-2023, Kakadu. *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

open Base
open Zanuda_core
open Zanuda_core.Utils

type input = Tast_iterator.iterator

let lint_id = "tuple_matching"
let lint_source = LINT.FPCourse
let group = LINT.Style
let level = LINT.Warn

let documentation =
  {| 
The following code is recommended:

```ocaml
  let (a,b) = scru in rhs
```

And this piece of code is discouraged:

```ocaml
  match scru with 
  | (a,b) -> rhs
```
|}
  |> Stdlib.String.trim
;;

let describe_as_json () =
  describe_as_clippy_json lint_id ~group ~level ~docs:documentation
;;

let msg ppf () = Caml.Format.fprintf ppf "Using `in` is recommended%!"

let report filename ~loc =
  let module M = struct
    let txt ppf () = Utils.Report.txt ~filename ~loc ppf msg ()

    let rdjsonl ppf () =
      RDJsonl.pp
        ppf
        ~filename:(Config.recover_filepath loc.loc_start.pos_fname)
        ~line:loc.loc_start.pos_lnum
        msg
        ()
    ;;
  end
  in
  (module M : LINT.REPORTER)
;;

let with_Tpat_tuple cs =
  let open Typedtree in
  match cs.c_lhs.pat_desc with
  | Tpat_value v ->
    (match (v :> pattern) with
     | { pat_desc = Tpat_tuple _ } -> true
     | _ -> false)
  | _ -> false
;;

let run _ fallback =
  let pat =
    let open Tast_pattern in
    texp_match (texp_ident drop) __
  in
  let open Tast_iterator in
  { fallback with
    expr =
      (fun self expr ->
        let open Typedtree in
        let loc = expr.exp_loc in
        Tast_pattern.parse
          pat
          loc
          expr
          (fun cases () ->
            match cases with
            | [ cs ] when with_Tpat_tuple cs ->
              CollectedLints.add
                ~loc
                (report loc.Location.loc_start.Lexing.pos_fname ~loc)
            | _ -> ())
          ~on_error:(fun _desc () -> fallback.expr self expr)
          ())
  }
;;