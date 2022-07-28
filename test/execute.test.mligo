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

(* Successful execution *)
let test_success =
  let (msig, keys, _) = bootstrap () in
  let prop_id =
    Multisig_helper.make_endorsed_proposal (keys, Multisig_helper.dummy_hash, msig.addr, msig.taddr) in
  (* let (pub_key, secret_key) = List_helper.nth_exn 1 keys in *)
  Test.log prop_id
