#import "./helpers/multisig.mligo" "Multisig_helper"
#import "./helpers/list.mligo" "List_helper"
#import "./helpers/log.mligo" "Log"
#import "./helpers/assert.mligo" "Assert"
#import "./bootstrap/bootstrap.mligo" "Bootstrap"
#import "../src/main.mligo" "Multisig"

let () = Log.describe("[Propose] test suite")

(* Boostrapping of the test environment, *)
let bootstrap () = Bootstrap.boot(5n, 2n, 3n)

(* Successful proposal creation *)
let test_success =
  let (msig, keys, _) = bootstrap () in
  let (pub_key, secret_key) = List_helper.nth_exn 1 keys in
  let s = Test.get_storage (msig.taddr) in
  let sig =
    Multisig_helper.make_sig
      (secret_key, msig.addr, s.next_proposal_id,
       Multisig_helper.dummy_hash) in
  let p =
    {hash_ = Multisig_helper.dummy_hash;
     pub_key = pub_key;
     sig = sig} in
  Multisig_helper.propose_success (p, msig.taddr)

(* Failure because not authorized *)
let test_failure =
  let (msig, _, unknown) = bootstrap () in
  let (pub_key, secret_key) = List_helper.nth_exn 1 unknown in
  let s = Test.get_storage (msig.taddr) in
  let sig =
    Multisig_helper.make_sig
      (secret_key, msig.addr, s.next_proposal_id,
       Multisig_helper.dummy_hash) in
  let p =
    {hash_ = Multisig_helper.dummy_hash;
     pub_key = pub_key;
     sig = sig} in
  let r = Multisig_helper.propose (p, msig.taddr) in
  Assert.string_failure r Multisig.Errors.not_authorized
