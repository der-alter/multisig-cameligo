#import "tezos-ligo-fa2/lib/fa2/asset/single_asset.mligo" "SingleAsset"
#import "tezos-ligo-fa2/test/fa2/single_asset.test.mligo" "SingleAsset_helper"
#import "./assert.mligo" "Assert"

(* Some types for readability *)
type taddr = (SingleAsset.parameter, SingleAsset.storage) typed_address
type contr = SingleAsset.parameter contract
type originated = {
    addr: address;
    taddr: taddr;
    owners: address list;
    ops: address list;
    contr: contr;
}

let get_initial_storage (msig, not_endorsers : (address * nat) * (address set)) =
  let (msig_addr, msig_tok_amount) = msig in

  let ledger = Big_map.literal ([
    (msig_addr, msig_tok_amount);
  ])
  in

  let ledger = Set.fold
    (fun (acc, addr : SingleAsset.Ledger.t * address) -> Big_map.add addr 0n acc)
    not_endorsers
    ledger
  in

  let token_metadata = {
      token_id = 1n;
      token_info = (Map.empty : (string, bytes) map)
} in

  {
    ledger         = ledger;
    token_metadata = token_metadata;
    operators      = (Big_map.empty : SingleAsset.Operators.t);
  }

let originate (init_storage : SingleAsset.storage) =
    let (taddr, _, _) = Test.originate SingleAsset.main init_storage 0tez in
    let contr = Test.to_contract taddr in
    let addr = Tezos.address contr in
    { addr = addr; taddr = taddr; contr = contr }

(* assert for FA2 insuffiscient balance string failure *)
let assert_ins_balance_failure (r : test_exec_result) =
    Assert.string_failure r SingleAsset.Errors.ins_balance

(* assert FA2 contract at [taddr] have [owner] address with [amount_] tokens in its ledger *)
let assert_balance_amount (taddr, owner, amount_ : taddr * SingleAsset.Ledger.owner * nat) =
    let s = Test.get_storage taddr in
    match Big_map.find_opt owner s.ledger with
        Some tokens -> assert(tokens = amount_)
        | None -> Test.failwith("Big_map key should not be missing")

(* get balance in [taddr] contract for [owner] address *)
let get_balance_for (taddr, owner : taddr * SingleAsset.Ledger.owner) =
    let s = Test.get_storage taddr in
    match Big_map.find_opt owner s.ledger with
        Some amount_ -> amount_
        | None -> 0n
