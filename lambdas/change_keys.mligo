#import "../src/outcome.mligo" "Outcome"

(* 
    The storage will be updated with the differences when the lambda is 
    executed
*)

let lambda_ : Outcome.change_keys =
  fun () ->
    (2n,
     (Set.literal
       [("edpkvYqwmqNiRdzHKxbdr3iuV7aduW4DcckgdaTtAbXdBu5Gu5hpur" : key);
         ("edpkuRE8nzHH4DoEk6M2Cb7LzsbC6wbyhCMDm4xfdFkRo8KXqdoGbY" : key);
         ("edpktyYDHTqViuh29hdaRsLn6UsqUkgKRk4wEGRUkv5URFHfTjSa43" : key)] : key set))
