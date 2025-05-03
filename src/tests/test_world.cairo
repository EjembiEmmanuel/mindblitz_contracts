#[cfg(test)]
mod tests {
    use dojo_cairo_test::WorldStorageTestTrait;
    // use dojo::model::{ModelStorage, ModelStorageTest};
    // use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
    };

    // use mindblitz::interfaces::IMindBlitz::{IMindBlitzDispatcher, IMindBlitzDispatcherTrait};
    use mindblitz::systems::Mindblitz::Mindblitz;

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "mindblitz",
            resources: [TestResource::Contract(Mindblitz::TEST_CLASS_HASH)].span(),
        };

        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"mindblitz", @"mindblitz")
                .with_writer_of([dojo::utils::bytearray_hash(@"mindblitz")].span())
        ]
            .span()
    }

    #[test]
    fn test_world_test_set() {
        // Initialize test environment
        // let caller = starknet::contract_address_const::<0x0>();
        let ndef = namespace_def();

        // Register the resources.
        let mut world = spawn_test_world([ndef].span());

        // Ensures permissions and initializations are synced.
        world.sync_perms_and_inits(contract_defs());
    }
}
