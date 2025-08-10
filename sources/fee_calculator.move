module prabhas_addr::FeeCalculator {
    use aptos_framework::signer;
    use aptos_framework::timestamp;

    struct NetworkFeeConfig has store, key {
        base_fee: u64,       
        congestion_multiplier: u64, 
        last_updated: u64,   
        is_active: bool,        
    }
    
    const E_NOT_INITIALIZED: u64 = 1;
    const E_INVALID_MULTIPLIER: u64 = 2;
    const E_NOT_AUTHORIZED: u64 = 3;
    public entry fun initialize_fee_config(admin: &signer, base_fee: u64, initial_multiplier: u64) {
        assert!(initial_multiplier <= 10000, E_INVALID_MULTIPLIER); 
        let config = NetworkFeeConfig {
            base_fee,
            congestion_multiplier: initial_multiplier,
            last_updated: timestamp::now_seconds(),
            is_active: true,
        };
        move_to(admin, config);
    }

    public fun calculate_dynamic_fee(
        admin_addr: address, 
        transaction_size: u64, 
        current_congestion: u64
    ): u64 acquires NetworkFeeConfig {
        assert!(exists<NetworkFeeConfig>(admin_addr), E_NOT_INITIALIZED);
        
        let config = borrow_global<NetworkFeeConfig>(admin_addr);
        assert!(config.is_active, E_NOT_AUTHORIZED);

        let size_fee = config.base_fee * transaction_size;
    
        let congestion_fee = (size_fee * current_congestion * config.congestion_multiplier) / 1000000;
        

        size_fee + congestion_fee
    }


    public fun get_fee_config(admin_addr: address): (u64, u64, u64, bool) acquires NetworkFeeConfig {
        assert!(exists<NetworkFeeConfig>(admin_addr), E_NOT_INITIALIZED);
        let config = borrow_global<NetworkFeeConfig>(admin_addr);
        (config.base_fee, config.congestion_multiplier, config.last_updated, config.is_active)
    }
}