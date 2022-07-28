#import "./helpers/token.mligo" "Token_helper"
#import "./helpers/multisig.mligo" "Multisig_helper"
#import "./helpers/list.mligo" "List_helper"
#import "./helpers/log.mligo" "Log"
#import "./helpers/assert.mligo" "Assert"
#import "./bootstrap/bootstrap.mligo" "Bootstrap"
#import "../src/main.mligo" "Multisig"

let () = Log.describe("[Endorse] test suite")

(* Boostrapping of the test environment, *)
let bootstrap () = Bootstrap.boot(5n, 2n, 3n)

(* Successful endorsement *)
let test_success =
  let (msig, keys, _) = bootstrap () in
  let (pub_key, secret_key) = List_helper.nth_exn 1 keys in
  let prop_id =
    Multisig_helper.make_proposal
      (pub_key, secret_key, Multisig_helper.dummy_hash,
       msig.addr, msig.taddr) in
  let sig =
    Multisig_helper.make_sig (secret_key, msig.addr, prop_id, Multisig_helper.dummy_hash) in
  let endorsement = {
      proposal_id = prop_id;
      pub_key = pub_key;
      sig = sig;
    } in
  Multisig_helper.endorse_success(endorsement, msig.taddr)

(* Failure because not authorized *)
let test_failure_not_authorized =
  let (msig, keys, unknown) = bootstrap () in
  let (pub_key, secret_key) = List_helper.nth_exn 1 keys in
  let (unknown_key, unknown_secret_key) = List_helper.nth_exn 1 unknown in
  let prop_id =
    Multisig_helper.make_proposal
      (pub_key, secret_key, Multisig_helper.dummy_hash,
       msig.addr, msig.taddr) in
  let sig =
    Multisig_helper.make_sig (unknown_secret_key, msig.addr, prop_id, Multisig_helper.dummy_hash) in
  let endorsement = {
      proposal_id = prop_id;
      pub_key = unknown_key;
      sig = sig;
    } in
  let r = Multisig_helper.endorse(endorsement, msig.taddr) in
  Assert.string_failure r Multisig.Errors.not_authorized

(* Failure because missigned *)
let test_failure_missigned =
  let (msig, keys, _) = bootstrap () in
  let (pub_key, secret_key) = List_helper.nth_exn 1 keys in
  let (other_pub_key, _) = List_helper.nth_exn 2 keys in
  let prop_id =
    Multisig_helper.make_proposal
      (pub_key, secret_key, Multisig_helper.dummy_hash,
       msig.addr, msig.taddr) in
  let sig =
    Multisig_helper.make_sig (secret_key, msig.addr, prop_id, Multisig_helper.dummy_hash) in
  let endorsement = {
      proposal_id = prop_id;
      pub_key = other_pub_key;
      sig = sig;
    } in
  let r = Multisig_helper.endorse(endorsement, msig.taddr) in
  Assert.string_failure r Multisig.Errors.missigned
