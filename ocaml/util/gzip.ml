(* Copyright (C) 2007 XenSource Inc *)

open Pervasiveext

module D = Debug.Debugger(struct let name="zcat" end)
open D

(** Path to the gzip binary *)
let gzip = "/bin/gzip"

(** Helper function to prevent double-closes of file descriptors *)
let close to_close fd = 
  if List.mem fd !to_close then Unix.close fd;
  to_close := List.filter (fun x -> fd <> x) !to_close 

type zcat_mode = Compress | Decompress

type input_type = 
  | Active  (** we provide a function which writes into the compressor and a fd output *)
  | Passive (** we provide an fd input and a function which reads from the compressor *)

(** Runs a zcat process which is either:
    i) a compressor; or (ii) a decompressor
    and which has either
    i) an active input (ie a function and a pipe) + passive output (fd); or
    ii) a passive input (fd) + active output (ie a function and a pipe)
*)
let go (mode: zcat_mode) (input: input_type) fd f = 
    let zcat_out, zcat_in = Unix.pipe() in
    
    let to_close = ref [ zcat_in; zcat_out ] in
    let close = close to_close in
    
    finally
      (fun () ->
	 let args = if mode = Compress then [] else ["--decompress"] @ [ "--stdout"; "--force" ] in

	 debug "Forking: %s [ %s ]" gzip (String.concat "; " args);
	 let dups, close_now, close_later = match input with
	   | Active -> 
	       [ Forkhelpers.Dup2(fd, Unix.stdout);        (* supplied fd is written to *)
		 Forkhelpers.Dup2(zcat_out, Unix.stdin) ], (* input comes from the pipe+fn *)
	       zcat_out,                                   (* we close this now *)
	       zcat_in                                     (* close this before waitpid *)
	   | Passive -> 
	       [ Forkhelpers.Dup2(fd, Unix.stdin);         (* supplied fd is read from *)
		 Forkhelpers.Dup2(zcat_in, Unix.stdout) ], (* output goes into the pipe+fn *) 
	       zcat_in,                                    (* we close this now *)
	       zcat_out in                                 (* close this before waitpid *)
	 let pid = Forkhelpers.safe_close_and_exec dups
	   [ Unix.stdout; Unix.stdin; ] (* close all but these *)
	   gzip args in
	 close close_now;
	 finally
	   (fun () -> f close_later)
	   (fun () ->
	      let failwith_error s =
		let mode = if mode = Compress then "Compression" else "Decompression" in
		let msg = Printf.sprintf "%s via zcat failed: %s" mode s in
		error "%s" msg;
		failwith msg
	        in
	      close close_later;
	      match snd (Unix.waitpid [] pid) with
	      | Unix.WEXITED 0 -> (); debug "OK";
	      | Unix.WEXITED i -> failwith_error (Printf.sprintf "exit code %d" i)
	      | Unix.WSIGNALED i -> failwith_error (Printf.sprintf "killed by signal %d" i)
	      | Unix.WSTOPPED i -> failwith_error (Printf.sprintf "stopped by signal %d" i)
	   )
      ) (fun () -> List.iter close !to_close)

let compress = go Compress Active
let decompress = go Decompress Active

let decompress_passive = go Decompress Passive