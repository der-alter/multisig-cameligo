#import "./constants.mligo" "Constants"
#import "./storage.mligo" "Storage"
#import "./proposal.mligo" "Proposal"
#import "./outcome.mligo" "Outcome"
#import "./errors.mligo" "Errors"

type parameter = 
  Default of unit
  | Propose of Proposal.make_params 
  | Endorse of Proposal.endorse_params
  | Execute of Proposal.execute_params
  | Cancel of Proposal.id

type storage = Storage.t

type result = operation list * storage

let _check_amount_is_zero () =
  assert_with_error
    (Tezos.get_amount () = 0mutez)
    Errors.not_zero_amount

let propose (p, s : Proposal.make_params * storage) =
  let () = _check_amount_is_zero () in
  let {hash_; pub_key; sig} = p in
  let () = Storage._check_is_authorized (pub_key, s) in
  let () = Proposal._check_sig (pub_key, s.next_proposal_id, hash_, sig) in
  Constants.no_operation, Storage.create_proposal
    (Proposal.make (hash_, pub_key), s)

let endorse (p, s : Proposal.endorse_params * storage) : result =
  let () = _check_amount_is_zero () in
  let {proposal_id; pub_key; sig} = p in
  let () = Storage._check_is_authorized (pub_key, s) in
  let prop = Proposal.get (proposal_id, s.proposals) in
  let () = Proposal._check_sig (pub_key, proposal_id, prop.hash, sig) in
  let prop = Proposal.endorse (prop, pub_key) in
    Constants.no_operation,
    Storage.update_proposal (proposal_id, prop, s)

let execute (p, s : Proposal.execute_params * storage) =
  let prop = Proposal.get (p.proposal_id, s.proposals) in
  if Set.cardinal prop.endorsements >= s.threshold
  then
    let outcome = Outcome.unpack (prop.hash, p.packed) in
    match outcome with
      Operation o ->
        o (), Storage.remove_proposal (p.proposal_id, s)
    | ChangeKeys ck ->
        let (threshold, keys) = ck () in
        let s = Storage.remove_proposal (p.proposal_id, s) in
          Constants.no_operation,
          { s with threshold = threshold; keys = keys }
  else failwith Errors.not_executable

let cancel (proposal_id, s : Proposal.id * storage) =
  (* let () = Storage._check_is_authorized (pub_key, s) in *)
  Constants.no_operation, Storage.remove_proposal (proposal_id, s)

let main (action, store : parameter * storage) : result =
  match action with
    Default () -> Constants.no_operation, store
    | Propose (p) -> propose (p, store)
    | Endorse (p) -> endorse (p, store)
    | Execute (p) -> execute (p, store)
    | Cancel (n) -> cancel (n, store)
