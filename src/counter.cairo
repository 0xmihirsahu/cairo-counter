#[starknet::interface]
pub trait ICounter<T>{
    fn get_counter(self: @T) -> u32;
    fn increase_counter(ref self: T) -> ();
}

#[starknet::contract]
pub mod counter_contract {
    use workshop::counter::ICounter;
    use starknet::ContractAddress;
    use kill_switch::{IKillSwitchDispatcher, IKillSwitchDispatcherTrait};

    #[storage]
    struct Storage {
        counter: u32,
        kill_switch: ContractAddress
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_value: u32, kill_switch_address: ContractAddress) {
        self.counter.write(initial_value);
        self.kill_switch.write(kill_switch_address);
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncreased: CounterIncreased,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        value: u32 ,
    }

    #[abi(embed_v0)]
    impl CounterImpl of ICounter<ContractState>{
        fn get_counter(self: @ContractState) -> u32{
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState) -> () {
            let kill_switch = IKillSwitchDispatcher{ contract_address: self.kill_switch.read()};

            assert!(!kill_switch.is_active(), "Kill Switch is active");
            self.counter.write(self.counter.read() + 1);
            self.emit(CounterIncreased { value: self.counter.read() });
            
        }
    }
}