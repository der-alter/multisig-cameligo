#import "./outcome.mligo" "Outcome"
#import "./errors.mligo" "Errors"

type t = {endorsements : key set; hash : bytes}
type id = nat
type proposals = (id, t) big_map

type make_params =
  [@layout:comb]
  {hash_ : bytes;
   pub_key : key;
   sig : signature}

type endorse_params =
  [@layout:comb]
  {proposal_id : id;
   pub_key : key;
   sig : signature}

type execute_params =
  [@layout:comb] {proposal_id : id; packed : bytes}

let make (hash_, pub_key : bytes * key) : t =
  {endorsements = Set.literal [pub_key]; hash = hash_}

let get (id, p : id * proposals) : t =
  match Big_map.find_opt id p with
    None -> failwith Errors.not_found_proposal
  | Some (p) -> p

let endorse (p, pub_key : t * key) : t =
  {p with
    endorsements = Set.add pub_key p.endorsements}

let next_id (current_id : id) : id = current_id + 1n

let _check_sig
  (pub_key, proposal_id, hash_, sig :
   key * nat * bytes * signature) =
  let msg =
    Bytes.pack
      ((Tezos.get_chain_id (), Tezos.get_self_address ()),
       (proposal_id, hash_)) in
  assert_with_error
    (Crypto.check pub_key sig msg)
    Errors.missigned
