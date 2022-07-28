#import "../src/outcome.mligo" "Outcome"

(* 
    Sample lambda code for an empty list of operations
    Notice that a type from the Outcome module is used
    See Makefile lambda-compile and lambda-hash targets for usage with ligo CLI
*)

let lambda_ : Outcome.operation =
  fun () -> ([] : operation list)
