#import "./proposal.mligo" "Proposal"
#import "./metadata.mligo" "Metadata"
#import "./errors.mligo" "Errors"

type t =
  [@layout:comb]
  {metadata : Metadata.t;
   proposals : Proposal.proposals;
   keys : key set;
   threshold : nat;
   next_proposal_id : Proposal.id}

let create_proposal (p, s : Proposal.t * t) : t =
  {s with
    next_proposal_id = Proposal.next_id(s.next_proposal_id);
    proposals = Big_map.add s.next_proposal_id p s.proposals}

let update_proposal (id, p, s : Proposal.id * Proposal.t * t) : t =
  {s with
    proposals = Big_map.update id (Some p) s.proposals}

let remove_proposal (id, s : Proposal.id * t) =
  {s with proposals = Big_map.remove id s.proposals}

let _check_is_authorized (pub_key, s : key * t) =
  assert_with_error (Set.mem pub_key s.keys) Errors.not_authorized
