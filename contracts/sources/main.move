module my_addrx::ScholarshipPlatform {
    
    use std::signer;
    use std::vector;
    use std::timestamp;
    use std::string::{String};
    use std::string::utf8;

    const GLOBAL_DONOR_ADDRESS: address = @donor_addrx;
    const GLOBAL_APPLICANT_ADDRESS: address = @applicant_addrx;

    struct Coin has store {
        value: u64
    }

    struct Balance has key {
        coin: Coin
    }

    struct Scholarship has key, copy, drop, store {
        scholarship_id: u64,       // Unique ID of the scholarship
        name: String,              // Scholarship name as String
        donor: address,            // Address of the donor
        criteria_gpa: u64,         // Minimum GPA required to apply
        field_of_study: String,    // Required field of study as String
        end_time: u64,             // Application deadline
        is_open: bool,             // Whether the scholarship is accepting 
        amount_per_applicant: u64,
        total_applicants: u64,
    }

    struct Scholarships has key, store{
        scholarships: vector<Scholarship>, // List of scholarships
    }

    struct DonorAddresses has key, store {
        addresses: vector<address>, // list of dnoar address
    }

    struct ScholarshipWithDonor has copy, drop, store {
        scholarship: Scholarship,
        donor_address: address, // Include donor address
    }

    struct Application has key, store {
        applicant: address, // Address of the applicant
        gpa: u64,
        field_of_study: String,
        scholarship_id: u64,
    }

    struct Applications has key {
        applications: vector<Application>, // List of applications
    }

    struct ApplicantAddresses has key, store {
        addresses: vector<address>, // list of applicant addresses
    }

    struct ApplicantData has copy, drop {
        applicant_address: address,
        gpa: u64,
    }

    public entry fun initialize_balance(user: &signer) {
        let user_address = signer::address_of(user);
        assert!(!exists<Balance>(user_address), E_BALANCE_ALREADY_INITIALIZED);
        
        let empty_coin = Coin { value: 0 };
        move_to(user, Balance { coin: empty_coin });
    }

    public entry fun issue_tokens(user: &signer, amount: u64) acquires Balance {
        let balance_ref = &mut borrow_global_mut<Balance>(signer::address_of(user)).coin.value;
        *balance_ref = *balance_ref + amount;
    }

    public  fun get_balance(account: address): u64 acquires Balance {
        borrow_global<Balance>(account).coin.value
    }

    public entry fun transfer_tokens(from: &signer, to: address, amount: u64) acquires Balance {
        let from_addr = signer::address_of(from);
        assert!(get_balance(from_addr) >= amount, E_NOT_ENOUGH_TOKENS);
        let from_balance_ref = &mut borrow_global_mut<Balance>(from_addr).coin.value;
        *from_balance_ref = *from_balance_ref - amount;

        let to_balance_ref = &mut borrow_global_mut<Balance>(to).coin.value;
        *to_balance_ref = *to_balance_ref + amount;
    }

    public entry fun initialize_global_donor_list(admin: &signer) {
        assert!(!exists<DonorAddresses>(GLOBAL_DONOR_ADDRESS), E_ALREADY_HAS_DONORLIST);

        move_to<DonorAddresses>(admin, DonorAddresses { addresses: vector::empty() });
        
    }

    public entry fun initialize_global_applicant_list(admin: &signer) {
        assert!(!exists<ApplicantAddresses>(GLOBAL_APPLICANT_ADDRESS), E_ALREADY_HAS_APPLICANT_LIST);

        move_to<ApplicantAddresses>(admin, ApplicantAddresses { addresses: vector::empty() });
    }

    fun add_donor_address(donor_address: address) acquires DonorAddresses {
        let donor_addresses = borrow_global_mut<DonorAddresses>(GLOBAL_DONOR_ADDRESS);

        if (!vector::contains(&donor_addresses.addresses, &donor_address)) {
            vector::push_back(&mut donor_addresses.addresses, donor_address);
        };
    }

    public entry fun initialize_scholarships(user: &signer) {
        assert!(!exists<Scholarships>(signer::address_of(user)), E_ALREADY_INITIALIZED_SCHOLARSHIPS);

        move_to<Scholarships>(user, Scholarships { scholarships: vector::empty() });
    }

    public entry fun create_scholarship(
        user: &signer,
        scholarship_id: u64,
        name: String,
        amount_per_applicant: u64,
        total_applicants: u64,
        criteria_gpa: u64,
        field_of_study: String,
        end_time: u64
    ) acquires Scholarships, Balance, DonorAddresses {
        let donor_address = signer::address_of(user);
        let scholarships = borrow_global_mut<Scholarships>(donor_address);
        assert!(timestamp::now_seconds() < end_time, E_INVALID_SCHOLARSHIP_HAS_END_TIME_SHOULD_BE_IN_FUTURE);

        let new_scholarship = Scholarship {
            scholarship_id: scholarship_id,
            name: name,
            donor: donor_address,
            amount_per_applicant: amount_per_applicant,
            total_applicants:total_applicants,
            criteria_gpa: criteria_gpa,
            field_of_study: field_of_study,
            end_time: end_time,
            is_open: true,
        };

        assert!(criteria_gpa <= 10 && criteria_gpa >= 0, E_INVALID_GPA_BE_IN_0_TO_10);

        let total_amount = amount_per_applicant * total_applicants;

        assert!(get_balance(donor_address) >= total_amount, E_NOT_ENOUGH_TOKENS);

        let donor_balance_ref = &mut borrow_global_mut<Balance>(donor_address).coin.value;

        *donor_balance_ref = *donor_balance_ref - total_amount;

        vector::push_back(&mut scholarships.scholarships, new_scholarship);

        add_donor_address(donor_address); 
    }

    public fun get_scholarship_by_id_mut(
        scholarships: &mut vector<Scholarship>,
        scholarship_id: u64
    ): &mut Scholarship {
        let i = 0;
        while (i < vector::length(scholarships)) {
            let scholarship_ref = vector::borrow_mut(scholarships, i);
            if (scholarship_ref.scholarship_id == scholarship_id) {
                return scholarship_ref 
            };
            i = i + 1;
        };

        abort(E_INVALID_SCHOLARSHIP_OR_UNAUTHORIZED) 
    }

    public fun get_scholarship_by_id(
        scholarships: &vector<Scholarship>,
        scholarship_id: u64
    ): Scholarship {
        let i = 0;
        while (i < vector::length(scholarships)) {
            let scholarship = vector::borrow(scholarships, i);
            if (scholarship.scholarship_id == scholarship_id) {
                return *scholarship 
            };
            i = i + 1;
        };
        
        Scholarship {
            scholarship_id: 0,
            name: utf8(b"Invalid Scholarship ID"),
            donor: @0x0,
            amount_per_applicant: 0,
            total_applicants: 0,
            criteria_gpa: 0,
            field_of_study: utf8(b"Invalid Scholarship ID"),
            end_time: 0,
            is_open: false,
        }
    }

    fun update_scholarship_status_if_needed(scholarship: &mut Scholarship) {
        if (timestamp::now_seconds() > scholarship.end_time) {
            scholarship.is_open = false;
        }
    }

    fun get_donor_address_of_scholarship(scholarship_id: u64): address acquires DonorAddresses, Scholarships {
        let donor_addresses = borrow_global<DonorAddresses>(GLOBAL_DONOR_ADDRESS);
        
        for (i in 0..vector::length(&donor_addresses.addresses)) {
            let donor_address = vector::borrow(&donor_addresses.addresses, i);
            
            if (exists<Scholarships>(*donor_address)) {
                let scholarships = borrow_global<Scholarships>(*donor_address);
                
                for (j in 0..vector::length(&scholarships.scholarships)) {
                    let scholarship = vector::borrow(&scholarships.scholarships, j);
                    
                    if (scholarship.scholarship_id == scholarship_id) {
                        return *donor_address
                    };
                };
            };
        };
        
        return @0x0 
    }

    public entry fun apply_for_scholarship(
        user: &signer,
        scholarship_id: u64,
        gpa: u64,
        field_of_study: String
    ) acquires Scholarships, Applications, DonorAddresses, ApplicantAddresses {
        let applicant_address = signer::address_of(user);

        let donor_address = get_donor_address_of_scholarship(scholarship_id);

        assert!(exists<DonorAddresses>(GLOBAL_DONOR_ADDRESS), E_ALREADY_HAS_DONORLIST);

        assert!(exists<Scholarships>(donor_address), E_INVALID_SCHOLARSHIP);
        
        let scholarships = borrow_global_mut<Scholarships>(donor_address);
        
        let scholarship = get_scholarship_by_id(&mut scholarships.scholarships, scholarship_id);

        assert!(!(applicant_address == donor_address),E_DONOR_CANNOT_APPLY);
        

        assert!(gpa <= 10 && gpa >= 0, E_INVALID_GPA_BE_IN_0_TO_10);

        assert!(!exists<Applications>(applicant_address), E_ALREADY_APPLIED);

        if (!exists<Applications>(applicant_address)) {
            move_to<Applications>(user, Applications { applications: vector::empty() });
        };

        assert!(scholarship.is_open, E_INVALID_SCHOLARSHIP_IS_CLOSED);

        assert!(timestamp::now_seconds() <= scholarship.end_time, E_INVALID_SCHOLARSHIP_HAS_TIME_ENDED);


        assert!(gpa >= scholarship.criteria_gpa,E_LOW_GPA_NOT_APPLICABLE );

        assert!(field_of_study == scholarship.field_of_study, E_FIELD_OF_STUDY_NOT_MATCHED);
        let applications = borrow_global_mut<Applications>(applicant_address);

        for (i in 0..vector::length(&applications.applications)) {
            let existing_application = vector::borrow(&applications.applications, i);

            assert!(existing_application.scholarship_id != scholarship_id, E_ALREADY_APPLIED);
        };

        let new_application = Application {
            applicant: applicant_address,
            gpa: gpa,
            field_of_study: field_of_study,
            scholarship_id: scholarship_id,
        };
        vector::push_back(&mut applications.applications, new_application);
        add_applicant_address(applicant_address);
    }    

    public entry fun distribute_scholarship(
        user: &signer,
        scholarship_id: u64
    ) acquires Scholarships, Balance, ApplicantAddresses, Applications {
        let donor_address = signer::address_of(user);
        let scholarships = borrow_global_mut<Scholarships>(donor_address);
        let scholarship = get_scholarship_by_id_mut(&mut scholarships.scholarships, scholarship_id);


        assert!(scholarship.donor == donor_address, E_UNAUTHORIZED_ACCESS_NOT_OWNER);

        assert!(scholarship.is_open, E_INVALID_SCHOLARSHIP_IS_CLOSED);

        assert!(timestamp::now_seconds() > scholarship.end_time, E_INVALID_SCHOLARSHIP_HAS_TIME_LEFT_PLEASE_WAIT_FOR_IT);

        let num_applicant = view_count_applicants_for_scholarship(scholarship_id);

        if (num_applicant == 0) {
            let donor_balance_ref = &mut borrow_global_mut<Balance>(donor_address).coin.value;

            let total_amount = scholarship.amount_per_applicant * scholarship.total_applicants;

            *donor_balance_ref = *donor_balance_ref + total_amount;

        } else {
            let total_amount = scholarship.amount_per_applicant * scholarship.total_applicants;

            let applicants = view_applicants_by_scholarship_id(scholarship_id);

            for (i in 0..vector::length(&applicants)){
                let applicants_address = vector::borrow(&applicants, i);

                let applicants_balance_ref = &mut borrow_global_mut<Balance>(*applicants_address).coin.value;

                *applicants_balance_ref = *applicants_balance_ref + scholarship.amount_per_applicant;
            };

            let remaining_amount = total_amount - scholarship.amount_per_applicant * num_applicant;

            let donor_balance_ref = &mut borrow_global_mut<Balance>(donor_address).coin.value;

            *donor_balance_ref = *donor_balance_ref + remaining_amount;
        };
        scholarship.is_open = false; 
    }

    public entry fun emergency_close_scholarship(
        user: &signer,
        scholarship_id: u64
    ) acquires Scholarships, Balance{
        let donor_address = signer::address_of(user);

        assert!(exists<Scholarships>(donor_address), E_UNAUTHORIZED_ACCESS_NOT_OWNER);

        let scholarships = borrow_global_mut<Scholarships>(donor_address);

        let scholarship_ref = get_scholarship_by_id_mut(&mut scholarships.scholarships, scholarship_id);

        assert!(scholarship_ref.donor == donor_address, E_UNAUTHORIZED_ACCESS_NOT_OWNER);

        assert!(scholarship_ref.is_open, E_INVALID_SCHOLARSHIP_IS_CLOSED);


        let total_amount = scholarship_ref.amount_per_applicant * scholarship_ref.total_applicants;

        let donor_balance_ref = &mut borrow_global_mut<Balance>(donor_address).coin.value;

        *donor_balance_ref = *donor_balance_ref + total_amount;

        scholarship_ref.is_open = false;
    }

    fun add_applicant_address(applicant_address: address) acquires ApplicantAddresses {
        let applicant_addresses = borrow_global_mut<ApplicantAddresses>(GLOBAL_APPLICANT_ADDRESS);

        if (!vector::contains(&applicant_addresses.addresses, &applicant_address)) {
            vector::push_back(&mut applicant_addresses.addresses, applicant_address);
        };
    }

    #[view]
    public fun view_donor_address_of_scholarship(scholarship_id: u64): address acquires DonorAddresses, Scholarships {
        get_donor_address_of_scholarship(scholarship_id)
    }

    #[view]
    public fun view_account_balance(account: address): u64 acquires Balance {
        if (exists<Balance>(account)) {
            return get_balance(account)
        } else {
            return 0
        }
    }

    #[view]
    public fun view_all_donor_addresses(): vector<address> acquires DonorAddresses {
        let donor_addresses = borrow_global<DonorAddresses>(GLOBAL_DONOR_ADDRESS);

        return donor_addresses.addresses
    }


    #[view]
    public fun view_all_scholarships(): vector<Scholarship> acquires DonorAddresses, Scholarships {
        let all_scholarships = vector::empty<Scholarship>();
        let donor_addresses = borrow_global<DonorAddresses>(GLOBAL_DONOR_ADDRESS);

        for (i in 0..vector::length(&donor_addresses.addresses)) {
            let donor_address = vector::borrow(&donor_addresses.addresses, i);
            if (exists<Scholarships>(*donor_address)) {
                let scholarships = borrow_global<Scholarships>(*donor_address);

                for (j in 0..vector::length(&scholarships.scholarships)) {
                    let scholarship = vector::borrow(&scholarships.scholarships, j);

                    vector::push_back(
                        &mut all_scholarships,
                        *scholarship 
                    );
                };
            };
        };

        return all_scholarships
    }

    #[view]
    public fun view_all_scholarships_created_by_address(account: address): vector<Scholarship> acquires Scholarships {
        if (!exists<Scholarships>(account)) {
            return vector::empty<Scholarship>() 
        };

        let scholarships = borrow_global<Scholarships>(account);

        return scholarships.scholarships
    }

    #[view]
    public fun view_all_scholarships_applied_by_address(account: address): vector<u64> acquires Applications {
        let applications = borrow_global<Applications>(account);
        let applied_scholarship_ids = vector::empty<u64>();

        let count = vector::length(&applications.applications);
        let i = 0;

        if (!exists<Applications>(account)) {
            return vector::empty<u64>()
        };

        while (i < count) {
            let application = vector::borrow(&applications.applications, i);

            vector::push_back(&mut applied_scholarship_ids, application.scholarship_id);

            i = i + 1;
        };

        return applied_scholarship_id
    }

    #[view]
    public fun view_complete_data_applicants_by_scholarship_id(scholarship_id: u64): vector<ApplicantData> acquires ApplicantAddresses, Applications {
        let applicant_addresses = borrow_global<ApplicantAddresses>(GLOBAL_APPLICANT_ADDRESS);

        let all_applicants = vector::empty<ApplicantData>();

        for (i in 0..vector::length(&applicant_addresses.addresses)) {
            let applicant_address = vector::borrow(&applicant_addresses.addresses, i);

            if (exists<Applications>(*applicant_address)) {
                let applications = borrow_global<Applications>(*applicant_address);

                for (j in 0..vector::length(&applications.applications)) {
                    let application = vector::borrow(&applications.applications, j);

                    if (application.scholarship_id == scholarship_id) {
                        let applicant_data = ApplicantData {
                            applicant_address: *applicant_address,
                            gpa: application.gpa,
                        };
                        vector::push_back(&mut all_applicants, applicant_data);
                    };
                };
            };
        };

        return all_applicants
    }

    #[view]
    public fun view_applicants_by_scholarship_id(scholarship_id: u64): vector<address> acquires ApplicantAddresses, Applications {
        let applicant_addresses = borrow_global<ApplicantAddresses>(GLOBAL_APPLICANT_ADDRESS);

        let all_applicants = vector::empty<address>();

        for (i in 0..vector::length(&applicant_addresses.addresses)) {
            let applicant_address = vector::borrow(&applicant_addresses.addresses, i);

            if (exists<Applications>(*applicant_address)) {

                let applications = borrow_global<Applications>(*applicant_address);

                for (j in 0..vector::length(&applications.applications)) {
                    
                    let application = vector::borrow(&applications.applications, j);

                    if (application.scholarship_id == scholarship_id) {
                        vector::push_back(&mut all_applicants, *applicant_address);
                    };
                };
            };
        };

        return all_applicants
    }

    #[view]
    public fun view_count_applicants_for_scholarship(scholarship_id: u64): u64 acquires ApplicantAddresses, Applications {
        let applicant_addresses = borrow_global<ApplicantAddresses>(GLOBAL_APPLICANT_ADDRESS);
        let count = 0;

        for (i in 0..vector::length(&applicant_addresses.addresses)) {
            let applicant_address = vector::borrow(&applicant_addresses.addresses, i);

            if (exists<Applications>(*applicant_address)) {
                let applications = borrow_global<Applications>(*applicant_address);

                for (j in 0..vector::length(&applications.applications)) {
                    let application = vector::borrow(&applications.applications, j);
                    if (application.scholarship_id == scholarship_id) {
                        count = count + 1;
                        break
                    };
                };
            };
        };

        return count
    }    
}
