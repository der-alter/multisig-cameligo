import dotenv from "dotenv";
import { MichelsonMap, TezosToolkit } from "@taquito/taquito";
import { InMemorySigner } from "@taquito/signer";
import { buf2hex } from "@taquito/utils";
import code from "../compiled/multisig.json";
import metadata from "./metadata.json";

// Read environment variables from .env file
dotenv.config();

// Initialize RPC connection
const Tezos = new TezosToolkit(process.env.NODE_URL);

// Deploy to configured node with configured secret key
const deploy = async () => {
  try {
    const signer = await InMemorySigner.fromSecretKey(process.env.SECRET_KEY);

    Tezos.setProvider({ signer });

    // create a JavaScript object to be used as initial storage
    // https://tezostaquito.io/docs/originate/#a-initializing-storage-using-a-plain-old-javascript-object
    const storage = {
      metadata: MichelsonMap.fromLiteral({
        "": buf2hex(Buffer.from("tezos-storage:contents")),
        contents: buf2hex(Buffer.from(JSON.stringify(metadata))),
      }),
      // ^ contract metadata (tzip-16)
      // https://tzip.tezosagora.org/proposal/tzip-16/

      proposals: new MichelsonMap(),
      keys: [
        "edpkvGfYw3LyB1UcCahKQk4rF2tvbMUk8GFiTuMjL75uGXrpvKXhjn", // alice
        "edpkurPsQ8eUApnLUJ9ZPDvu98E8VNj4KtJa1aZr16Cr5ow5VHKnz4", // bob
        "edpku3a3tjtvoR3zzisLYckHDCPE7YduZWAqs7KC2GDs52rr2WQHyV", // carol
        "edpkvXpMdKoyT8LQLEP3Z38nn8t6jkPHsW5eSbNpTu8FkNUkbWd6xn", // dave
        "edpku9qEgcyfNNDK6EpMvu5SqXDqWRLuxdMxdyH12ivTUuB1KXfGP4", // eve
      ],
      // initial set of endorsers keys
      // ^ these are known keys to the flextesa sandbox (deterministic strings)
      // docker run --rm oxheadalpha/flextesa:20220715 flextesa key alice
      threshold: 3,
      next_proposal_id: 0,
    };

    const op = await Tezos.contract.originate({ code, storage });
    await op.confirmation();
    console.log(`[OK] ${op.contractAddress}`);
  } catch (e) {
    console.log(e);
  }
};

deploy();
