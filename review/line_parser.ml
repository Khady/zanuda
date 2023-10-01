(** Copyright 2021-2023, Kakadu. *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

let use_logging = ref false
let set_logging flg = use_logging := flg
  if !use_logging
  then Format.kasprintf (Format.eprintf "%s\n%!") fmt
  else Format.ifprintf Format.std_formatter fmt
let similarity : unit parser =
  let* _ = string "similarity index" in
  many any_char *> return ()
;;

let rename : unit parser =
  let* _ = string "rename from" <|> string "rename to" in
  many any_char *> return ()
;;

  fun ?info ppp ->