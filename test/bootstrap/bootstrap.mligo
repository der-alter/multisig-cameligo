#import "../helpers/multisig.mligo" "Multisig_helper"

let get_keys (from : nat) (to : nat) =
  let rec aux (acc, i : (key * string) list * nat) : (key * string) list =
    let (_, pub_key, secret_key) = Test.get_bootstrap_account i in
    let acc = (pub_key, secret_key) :: acc in
    if i = to then acc else aux (acc, i + 1n) in
  aux (([] : (key * string) list), from)

let boot (nb_keys, nb_unknown, threshold : nat * nat * nat) =
  let nb_accounts = nb_keys + nb_unknown in
  let () =
    (* Add 1n to skip account 0 (default baking account) *)
    Test.reset_state (nb_accounts + 1n) ([] : tez list) in
  let keys = get_keys 1n nb_keys in
  let unknown = get_keys (nb_keys + 1n) nb_accounts in
  let pub_keys =
    List.fold_left
      (fun (acc, (pub_key, _) :
            key set * (key * string)) ->
         Set.add pub_key acc)
      (Set.empty : key set)
      keys in
  let init_storage =
    Multisig_helper.get_initial_storage (pub_keys, threshold) in
  let msig = Multisig_helper.originate (init_storage) in
  (msig, keys, unknown)
