module my_addrx::ScholarshipPlatform {
    use std::signer;
    use std::vector;
    use std::timestamp;
    use std::string::{String};
    use std::string::utf8;


    /// Error codes
    const E_NOT_ENOUGH_TOKENS: u64 = 1;
    const E_ALREADY_HAS_BALANCE: u64 = 2;
    const E_INVALID_SCHOLARSHIP: u64 = 3;
    const E_ALREADY_HAS_DONORLIST: u64 = 4;
    const E_ALREADY_INITIALIZED_SCHOLARSHIPS: u64 = 5;
    const E_ALREADY_APPLIED: u64 = 6;
    const E_INVALID_SCHOLARSHIP_HAS_TIME_ENDED: u64 = 7;
    const E_LOW_GPA_NOT_APPLICABLE: u64 = 8;
    const E_FIELD_OF_STUDY_NOT_MATCHED: u64 = 9;
    const E_NO_APPLICANTS: u64 = 10;
    const E_INVALID_SCHOLARSHIP_IS_CLOSED: u64 = 11;
    const E_INVALID_GPA_BE_IN_0_TO_10: u64 = 12;
    const E_DONOR_CANNOT_APPLY: u64 = 13;
    const E_UNAUTHORIZED_ACCESS_NOT_OWNER: u64 = 14;
    const E_BALANCE_ALREADY_INITIALIZED: u64 = 15;
    const E_ALREADY_HAS_APPLICANT_LIST : u64 = 16;
    const E_INVALID_SCHOLARSHIP_HAS_TIME_LEFT_PLEASE_WAIT_FOR_IT: u64 = 17;
    const E_INVALID_SCHOLARSHIP_OR_UNAUTHORIZED: u64 = 18;
    const E_INVALID_SCHOLARSHIP_HAS_END_TIME_SHOULD_BE_IN_FUTURE: u64 = 19;



    /// Global donor address where donor addresses are stored
    const GLOBAL_DONOR_ADDRESS: address = @donor_addrx;
    const GLOBAL_APPLICANT_ADDRESS: address = @applicant_addrx;

    // --- Token Structs ---
    struct Coin has store {
        value: u64
    }

    struct Balance has key {
        coin: Coin
    }

    // --- Scholarship Structs ---
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

    // --- Token Functions ---

    // Initialize the balance of a user
    public entry fun initialize_balance(user: &signer) {
        let user_address = signer::address_of(user);
        // Assert that the balance resource does not already exist
        assert!(!exists<Balance>(user_address), E_BALANCE_ALREADY_INITIALIZED);
        
        let empty_coin = Coin { value: 0 };
        move_to(user, Balance { coin: empty_coin });
    }

    // Issue tokens to a user (used by donors)
    public entry fun issue_tokens(user: &signer, amount: u64) acquires Balance {
        let balance_ref = &mut borrow_global_mut<Balance>(signer::address_of(user)).coin.value;
        *balance_ref = *balance_ref + amount;
    }

    /// Get the balance of a user
    public  fun get_balance(account: address): u64 acquires Balance {
        borrow_global<Balance>(account).coin.value
    }

    /// Transfer tokens from one account to another
    public entry fun transfer_tokens(from: &signer, to: address, amount: u64) acquires Balance {
        let from_addr = signer::address_of(from);
        assert!(get_balance(from_addr) >= amount, E_NOT_ENOUGH_TOKENS);
        let from_balance_ref = &mut borrow_global_mut<Balance>(from_addr).coin.value;
        *from_balance_ref = *from_balance_ref - amount;

        let to_balance_ref = &mut borrow_global_mut<Balance>(to).coin.value;
        *to_balance_ref = *to_balance_ref + amount;
    }

    // --- Donor Functions ---

    // --- Initialize DonorAddresses ---
    public entry fun initialize_global_donor_list(admin: &signer) {
        assert!(!exists<DonorAddresses>(GLOBAL_DONOR_ADDRESS), E_ALREADY_HAS_DONORLIST);

        move_to<DonorAddresses>(admin, DonorAddresses { addresses: vector::empty() });
        
    }

    public entry fun initialize_global_applicant_list(admin: &signer) {
        assert!(!exists<ApplicantAddresses>(GLOBAL_APPLICANT_ADDRESS), E_ALREADY_HAS_APPLICANT_LIST);

        move_to<ApplicantAddresses>(admin, ApplicantAddresses { addresses: vector::empty() });
    }

    // Add a donor address to the global list if it's not already there
    fun add_donor_address(donor_address: address) acquires DonorAddresses {
        let donor_addresses = borrow_global_mut<DonorAddresses>(GLOBAL_DONOR_ADDRESS);

        if (!vector::contains(&donor_addresses.addresses, &donor_address)) {
            vector::push_back(&mut donor_addresses.addresses, donor_address);
        };
    }


    // --- Scholarship Management ---

    public entry fun initialize_scholarships(user: &signer) {
        assert!(!exists<Scholarships>(signer::address_of(user)), E_ALREADY_INITIALIZED_SCHOLARSHIPS);

        move_to<Scholarships>(user, Scholarships { scholarships: vector::empty() });
    }

    // Create a scholarship
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

        // Ensure donor has enough tokens
        assert!(get_balance(donor_address) >= total_amount, E_NOT_ENOUGH_TOKENS);

        // Reserve the scholarship amount from the donor's balance
        let donor_balance_ref = &mut borrow_global_mut<Balance>(donor_address).coin.value;

        *donor_balance_ref = *donor_balance_ref - total_amount;

        vector::push_back(&mut scholarships.scholarships, new_scholarship);

        add_donor_address(donor_address); // Add the donor to the global donor list
    }

    // Modify this function to return a mutable reference
    public fun get_scholarship_by_id_mut(
        scholarships: &mut vector<Scholarship>,
        scholarship_id: u64
    ): &mut Scholarship {
        let i = 0;
        while (i < vector::length(scholarships)) {
            let scholarship_ref = vector::borrow_mut(scholarships, i);
            if (scholarship_ref.scholarship_id == scholarship_id) {
                return scholarship_ref // return the mutable reference
            };
            i = i + 1;
        };

        abort(E_INVALID_SCHOLARSHIP_OR_UNAUTHORIZED) // Handle invalid scholarship case
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

    // Function to find the donor address for a given scholarship ID
    fun get_donor_address_of_scholarship(scholarship_id: u64): address acquires DonorAddresses, Scholarships {
        // Fetch the list of all donor addresses
        let donor_addresses = borrow_global<DonorAddresses>(GLOBAL_DONOR_ADDRESS);
        
        // Loop through all donor addresses to find the one with the matching scholarship ID
        for (i in 0..vector::length(&donor_addresses.addresses)) {
            let donor_address = vector::borrow(&donor_addresses.addresses, i);
            
            // Check if the donor has any scholarships
            if (exists<Scholarships>(*donor_address)) {
                let scholarships = borrow_global<Scholarships>(*donor_address);
                
                // Loop through the donor's scholarships to find the matching one
                for (j in 0..vector::length(&scholarships.scholarships)) {
                    let scholarship = vector::borrow(&scholarships.scholarships, j);
                    
                    // Check if the scholarship_id matches
                    if (scholarship.scholarship_id == scholarship_id) {
                        return *donor_address
                    };
                };
            };
        };
        
        return @0x0 // Return a default address if no match is found
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

        // Ensure the donor's Scholarships resource exists
        assert!(exists<Scholarships>(donor_address), E_INVALID_SCHOLARSHIP);
        
        let scholarships = borrow_global_mut<Scholarships>(donor_address);
        
        let scholarship = get_scholarship_by_id(&mut scholarships.scholarships, scholarship_id);

        assert!(!(applicant_address == donor_address),E_DONOR_CANNOT_APPLY);
        

        assert!(gpa <= 10 && gpa >= 0, E_INVALID_GPA_BE_IN_0_TO_10);

        assert!(!exists<Applications>(applicant_address), E_ALREADY_APPLIED);

        if (!exists<Applications>(applicant_address)) {
            move_to<Applications>(user, Applications { applications: vector::empty() });
        };

        // Ensure there is not repeate applications

        // Ensure the scholarship is still open and the application period hasn't ended
        assert!(scholarship.is_open, E_INVALID_SCHOLARSHIP_IS_CLOSED);

        assert!(timestamp::now_seconds() <= scholarship.end_time, E_INVALID_SCHOLARSHIP_HAS_TIME_ENDED);


        assert!(gpa >= scholarship.criteria_gpa,E_LOW_GPA_NOT_APPLICABLE );

        assert!(field_of_study == scholarship.field_of_study, E_FIELD_OF_STUDY_NOT_MATCHED);
        
        // Ensure the applicant meets the minimum GPA requirement and field of study matches
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

        // Add the application to the user's applications
        vector::push_back(&mut applications.applications, new_application);
        

        // Call `add_applicant_address` to store the applicant's address
        add_applicant_address(applicant_address);
    }    

    // Distribute scholarship to qualified recipients
    public entry fun distribute_scholarship(
        user: &signer,
        scholarship_id: u64
    ) acquires Scholarships, Balance, ApplicantAddresses, Applications {
        let donor_address = signer::address_of(user);
        let scholarships = borrow_global_mut<Scholarships>(donor_address);
        let scholarship = get_scholarship_by_id_mut(&mut scholarships.scholarships, scholarship_id);

        // Only the donor who created the scholarship can close it

        assert!(scholarship.donor == donor_address, E_UNAUTHORIZED_ACCESS_NOT_OWNER);

        assert!(scholarship.is_open, E_INVALID_SCHOLARSHIP_IS_CLOSED);

        assert!(timestamp::now_seconds() > scholarship.end_time, E_INVALID_SCHOLARSHIP_HAS_TIME_LEFT_PLEASE_WAIT_FOR_IT);

        let num_applicant = view_count_applicants_for_scholarship(scholarship_id);

        if (num_applicant == 0) {
            // Refund the remaining balance to the donor's account
            let donor_balance_ref = &mut borrow_global_mut<Balance>(donor_address).coin.value;

            let total_amount = scholarship.amount_per_applicant * scholarship.total_applicants;

            *donor_balance_ref = *donor_balance_ref + total_amount;

        } else {
            let total_amount = scholarship.amount_per_applicant * scholarship.total_applicants;

            // Get the addresses of all applicants for this scholarship
            let applicants = view_applicants_by_scholarship_id(scholarship_id);

            // Distribute the tokens to each applicant
            for (i in 0..vector::length(&applicants)){
                let applicants_address = vector::borrow(&applicants, i);

                let applicants_balance_ref = &mut borrow_global_mut<Balance>(*applicants_address).coin.value;

                *applicants_balance_ref = *applicants_balance_ref + scholarship.amount_per_applicant;
            };

            let remaining_amount = total_amount - scholarship.amount_per_applicant * num_applicant;

            let donor_balance_ref = &mut borrow_global_mut<Balance>(donor_address).coin.value;

            *donor_balance_ref = *donor_balance_ref + remaining_amount;
        };
        scholarship.is_open = false; // Close the scholarship
    }

    // Function to close a scholarship in case of an emergency and refund the remaining balance to the donor
    // Only the creator (donor) of the scholarship can close it and get a refund.
    public entry fun emergency_close_scholarship(
        user: &signer,
        scholarship_id: u64
    ) acquires Scholarships, Balance{
        let donor_address = signer::address_of(user);

        // Check if the donor owns any scholarships
        assert!(exists<Scholarships>(donor_address), E_UNAUTHORIZED_ACCESS_NOT_OWNER);

        // Get the donor's scholarships
        let scholarships = borrow_global_mut<Scholarships>(donor_address);

        // Ensure the scholarship exists in the donor's list
        let scholarship_ref = get_scholarship_by_id_mut(&mut scholarships.scholarships, scholarship_id);

        // Only the donor who created the scholarship can close it
        assert!(scholarship_ref.donor == donor_address, E_UNAUTHORIZED_ACCESS_NOT_OWNER);

        // Check if the scholarship is still open
        assert!(scholarship_ref.is_open, E_INVALID_SCHOLARSHIP_IS_CLOSED);

        // Refund the remaining balance to the donor's account

        let total_amount = scholarship_ref.amount_per_applicant * scholarship_ref.total_applicants;

        let donor_balance_ref = &mut borrow_global_mut<Balance>(donor_address).coin.value;

        *donor_balance_ref = *donor_balance_ref + total_amount;

        // Close the scholarship by setting `is_open` to false
        scholarship_ref.is_open = false;
    }

    // Add an applicant to the global list in your `apply_for_scholarship` function
    fun add_applicant_address(applicant_address: address) acquires ApplicantAddresses {
        let applicant_addresses = borrow_global_mut<ApplicantAddresses>(GLOBAL_APPLICANT_ADDRESS);

        if (!vector::contains(&applicant_addresses.addresses, &applicant_address)) {
            vector::push_back(&mut applicant_addresses.addresses, applicant_address);
        };
    }

    // --- View Functions ---

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

    // View all scholarships on the platform with full details
    // This function will retrieve every scholarship and its donor across the platform.

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
                        *scholarship // Only pushing the scholarship, not the donor
                    );
                };
            };
        };

        return all_scholarships
    }

    // --- Get all scholarships created by a specific account ---
    #[view]
    public fun view_all_scholarships_created_by_address(account: address): vector<Scholarship> acquires Scholarships {
        // Check if the Scholarships resource exists for the given account
        if (!exists<Scholarships>(account)) {
            return vector::empty<Scholarship>() // Return an empty vector if no scholarships exist
        };

        // Borrow the Scholarships resource for the given account
        let scholarships = borrow_global<Scholarships>(account);

        return scholarships.scholarships // Return the vector of scholarships
    }

    // --- Get all scholarships applied for by a specific account ---
    #[view]
    public fun view_all_scholarships_applied_by_address(account: address): vector<u64> acquires Applications {
        // Borrow the Applications resource for the given account
        let applications = borrow_global<Applications>(account);
        let applied_scholarship_ids = vector::empty<u64>();

        let count = vector::length(&applications.applications);
        let i = 0;

        if (!exists<Applications>(account)) {
            return vector::empty<u64>() // Return an empty vector if no scholarships exist
        };

        // Iterate through the applications using an index
        while (i < count) {
            let application = vector::borrow(&applications.applications, i);

            vector::push_back(&mut applied_scholarship_ids, application.scholarship_id);

            i = i + 1;
        };

        return applied_scholarship_ids // Return the list of applied scholarship IDs
    }

    #[view]
    public fun view_complete_data_applicants_by_scholarship_id(scholarship_id: u64): vector<ApplicantData> acquires ApplicantAddresses, Applications {
        let applicant_addresses = borrow_global<ApplicantAddresses>(GLOBAL_APPLICANT_ADDRESS);

        // Vector to store full applicant data (address + GPA)
        let all_applicants = vector::empty<ApplicantData>();

        // Iterate over all applicant addresses
        for (i in 0..vector::length(&applicant_addresses.addresses)) {
            let applicant_address = vector::borrow(&applicant_addresses.addresses, i);

            // Check if the applicant has applied for any scholarships
            if (exists<Applications>(*applicant_address)) {
                let applications = borrow_global<Applications>(*applicant_address);

                // Check each application for the provided scholarship_id
                for (j in 0..vector::length(&applications.applications)) {
                    let application = vector::borrow(&applications.applications, j);

                    if (application.scholarship_id == scholarship_id) {
                        // Construct the ApplicantData struct with address and GPA
                        let applicant_data = ApplicantData {
                            applicant_address: *applicant_address,
                            gpa: application.gpa,  // Assuming 'gpa' is part of the application struct
                        };
                        // Add the full applicant data to the vector
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
                        count = count + 1; // Increment the count for each matching application
                        break // No need to check further applications for this applicant
                    };
                };
            };
        };

        return count // Return the total count of applicants for the given scholarship ID
    }
    
}
