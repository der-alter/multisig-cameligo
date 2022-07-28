#import "./helpers/token.mligo" "Token_helper"
#import "./helpers/multisig.mligo" "Multisig_helper"
#import "./helpers/log.mligo" "Log"
#import "./helpers/assert.mligo" "Assert"
#import "./bootstrap/bootstrap.mligo" "Bootstrap"
#import "../src/main.mligo" "Multisig"

let () = Log.describe("[Default] test suite")

(* Boostrapping of the test environment, *)
let bootstrap () = Bootstrap.boot(5n, 2n, 3n)

(* Successful transfer of tez *)
let test_transfer_tez =
    let (msig, _, _) = bootstrap() in 
    let vunit = Test.compile_value () in
    let _ = Test.transfer msig.addr vunit 30mutez in
    assert (Test.get_balance(msig.addr) = 30mutez)
