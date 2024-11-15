#[starknet::contract]
mod NameRegistry {
    use starknet::event::EventEmitter;
    use core::starknet::{ContractAddress, get_caller_address};
    use core::starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess
    };


    ///////////////////////////////////////////////////
    ///                 Events                      ///
    ///////////////////////////////////////////////////
    /// 
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        OwnerUpdated: OwnerUpdated,
        SenderRegistered: SenderRegistered,
    }

    #[derive(Drop, starknet::Event)]
    pub struct OwnerUpdated {
        #[key]
        previous_owner: ContractAddress,
        #[key]
        new_owner: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct SenderRegistered {
        #[key]
        sender: ContractAddress,
        name: felt252,
    }


    ///////////////////////////////////////////////////
    ///                 Storage                     ///
    ///////////////////////////////////////////////////
    #[storage]
    struct Storage {
        owner: Person,
        reg_count: u256,
        address_to_name: Map<ContractAddress, felt252>
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct Person {
        address: ContractAddress,
        name: felt252,
    }

    ///////////////////////////////////////////////////
    ///                 Contract                    ///
    ///////////////////////////////////////////////////
    /// 
    #[generate_trait]
    impl NameRegistry of INameRegistry {
        #[constructor]
        fn constructor(ref self: ContractState) {
            let admin: felt252 = 'MOHAN';
            self.owner.address.write(get_caller_address());
            self.owner.name.write(admin);
            self.reg_count.write(1);
        }

        fn update_owner(ref self: ContractState, new_owner: ContractAddress, name: felt252) {
            let caller = get_caller_address();
            assert!(caller == self.owner.address.read(), "Not Owner");
            assert!(caller != new_owner, "Already owner");
            let previous_owner = self.owner.address.read();
            self.owner.address.write(new_owner);
            self.owner.name.write(name);
        }

        fn register_sender(ref self: ContractState, name: felt252) {
            let caller = get_caller_address();
            assert!(self.address_to_name.entry(caller).read() == 0, "Address already registered");
            self.address_to_name.entry(caller).write(name);
            self.reg_count.write(self.reg_count.read() + 1);

            self.emit(SenderRegistered { sender: caller, name: name });
        }

        fn get_registration_info(self:@ContractState, address:ContractAddress) -> (ContractAddress,felt252){
            return (address,self.address_to_name.entry(address).read());
        }
    }
}
