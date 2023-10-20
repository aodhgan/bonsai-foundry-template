#![no_main]

use std::io::Read;

use ethabi::{ethereum_types::Address, ethereum_types::U256, ParamType, Token};
use risc0_zkvm::guest::env;

risc0_zkvm::guest::entry!(main);

fn main() {
    // Read data sent from the application contract.
    // println!("Reading input from stdin");
    let mut input_bytes = Vec::<u8>::new();
    env::stdin().read_to_end(&mut input_bytes).unwrap();
    // Type array passed to `ethabi::decode_whole` should match the types encoded in
    // the application contract.
    let input = ethabi::decode_whole(
        &[ParamType::Address, ParamType::Address, ParamType::Uint(256)],
        &input_bytes,
    )
    .unwrap();

    let from: Address = input[0].clone().into_address().unwrap();
    let to: Address = input[1].clone().into_address().unwrap();

    let amount: U256 = input[2].clone().into_uint().unwrap();

    // todo: Run the computation to generate a new root.

    // Commit the journal that will be received by the application contract.
    // Encoded types should match the args expected by the application callback.
    env::commit_slice(&ethabi::encode(&[
        Token::Address(from),
        Token::Address(to),
        Token::Uint(amount),
    ]));
}
