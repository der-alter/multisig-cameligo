#import "./errors.mligo" "Errors"

type change_keys = (unit -> (nat * key set))
(* ^ change treshold and list of public keys *)
type operation = (unit -> operation list)

type t = ChangeKeys of change_keys | Operation of operation

let unpack (hash_, packed : bytes * bytes) =
    let _check_hash = assert_with_error
        (hash_ = Crypto.sha256 packed)
        Errors.hash_mismatch
    in (match (Bytes.unpack packed : t option) with
        None -> failwith(Errors.unpack_mismatch)
        | Some o -> o)
