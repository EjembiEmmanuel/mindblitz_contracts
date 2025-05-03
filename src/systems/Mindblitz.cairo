// dojo decorator
#[dojo::contract]
pub mod Mindblitz {
    // use starknet::{ContractAddress, get_caller_address};

    // use dojo::model::{ModelStorage};
    // use dojo::event::EventStorage;

    use mindblitz::interfaces::IMindBlitz::IMindBlitz;


    #[abi(embed_v0)]
    impl MindBlitzImpl of IMindBlitz<ContractState> {}

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "mindblitz". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"mindblitz")
        }
    }
}
