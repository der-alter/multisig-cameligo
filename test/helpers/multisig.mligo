#import "../../src/main.mligo" "Multisig"
#import "./assert.mligo" "Assert"
#import "./list.mligo" "List_helper"

(* Some types for readability *)
type taddr = (Multisig.parameter, Multisig.storage) typed_address
type contr = Multisig.parameter contract
type originated = {
    addr: address;
    taddr: taddr;
    contr: contr;
}

(* this is the chain id in  test framework *)
let chain_id = 0x00000000

(* Some dummy values intended to be used as placeholders *)
let dummy_packed = Bytes.pack (Operation(fun () -> ([] : operation list)))
let dummy_hash = Crypto.sha256 dummy_packed

(* Some default values *)
let default_proposals = (Big_map.empty: Multisig.Proposal.proposals)
let default_metadata = Big_map.literal [
    ("", Bytes.pack("tezos-storage:contents"));
    ("contents", ("": bytes))
]

let get_initial_storage (keys, threshold : key set * nat) : Multisig.storage = {
    metadata = default_metadata;
    proposals = default_proposals;
    keys = keys;
    threshold = threshold;
    next_proposal_id = 1n;
}

(* Originate a Multisig contract with given init_storage storage *)
let originate (init_storage: Multisig.storage) =
    let (taddr, _, _) = Test.originate Multisig.main init_storage 0tez in
    let contr = Test.to_contract taddr in
    let addr = Tezos.address contr in
    { addr = addr; taddr = taddr; contr = contr }

(* Call entry point of Multisig contr contract *)
let call (p, contr : Multisig.parameter * contr) =
    Test.transfer_to_contract contr p 0mutez

(* Entry points call helpers *)
let propose(p, taddr : Multisig.Proposal.make_params * taddr) =
    let contr : Multisig.Proposal.make_params contract = Test.to_entrypoint "propose" taddr in
    Test.transfer_to_contract contr p 0mutez

let endorse(p, taddr : Multisig.Proposal.endorse_params * taddr) =
    let contr : Multisig.Proposal.endorse_params contract = Test.to_entrypoint "endorse" taddr in
    Test.transfer_to_contract contr p 0mutez

(* Asserter helper for successful entry point calls *)
let propose_success (p, taddr : Multisig.Proposal.make_params * taddr) =
    Assert.tx_success (propose(p, taddr))

let endorse_success (p, taddr : Multisig.Proposal.endorse_params * taddr) =
    Assert.tx_success (endorse(p, taddr))

(* Make a signature *)
let make_sig
  (secret_key, contr_addr, proposal_id, hash_ :
   string * address * nat * bytes) =
  let msg = ((chain_id, contr_addr), (proposal_id, hash_)) in
  Test.sign secret_key (Bytes.pack msg)

(* Make a proposal and return its id *)
let make_proposal (pub_key, secret_key, hash_, addr, taddr : key * string * bytes * address * taddr) =
  let s = Test.get_storage (taddr) in
  let msg = ((chain_id, addr), (s.next_proposal_id, hash_)) in
  let sig = Test.sign secret_key (Bytes.pack msg) in
  let p =
    {hash_ = dummy_hash;
     pub_key = pub_key;
     sig = sig} in
  let () = propose_success (p, taddr) in
  s.next_proposal_id

(* Make a proposal, endorse it, and return its id *)
let make_endorsed_proposal (keys, hash_, addr, taddr : (key * string) list * bytes * address * taddr) =
  let (pub_key, secret_key) = List_helper.nth_exn 1 keys in
  let prop_id = make_proposal (pub_key, secret_key, hash_, addr, taddr) in
  let () = List.iter (fun (keypair: (key * string)) -> 
    let (pub_key, secret_key) = keypair in
    let sig = make_sig (secret_key, addr, prop_id, dummy_hash) in
    endorse_success({
        proposal_id = prop_id;
        pub_key = pub_key;
        sig = sig;
      }, taddr)
  ) keys in 
  prop_id
