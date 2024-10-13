module my_addrx::ScholarshipPlatform {
    use std::{signer, vector, timestamp, string::{String, utf8}};
    const GLOBAL_DONOR_ADDRESS: address = @donor_addrx;
    const GLOBAL_APPLICANT_ADDRESS: address = @applicant_addrx;

    struct Coin has store { value: u64 }
    struct Balance has key { coin: Coin }
    struct Scholarship has key, copy, drop, store {
        scholarship_id: u64, name: String, donor: address, criteria_gpa: u64,
        field_of_study: String, end_time: u64, is_open: bool,
        amount_per_applicant: u64, total_applicants: u64,
    }
    struct Scholarships has key, store { scholarships: vector<Scholarship> }
    struct ScholarshipWithDonor has copy, drop, store {
        scholarship: Scholarship, donor_address: address,
    }
    struct Application has key, store {
        applicant: address, gpa: u64, field_of_study: String, scholarship_id: u64,
    }
    struct Applications has key { applications: vector<Application> }
    struct ApplicantAddresses has key, store { addresses: vector<address> }
    struct ApplicantData has copy, drop { applicant_address: address, gpa: u64 }

    public fun get_balance(account: address): u64 acquires Balance {
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

    public fun get_scholarship_by_id_mut(scholarships: &mut vector<Scholarship>, scholarship_id: u64): &mut Scholarship {
        let i = 0;
        while (i < vector::length(scholarships)) {
            let scholarship_ref = vector::borrow_mut(scholarships, i);
            if (scholarship_ref.scholarship_id == scholarship_id) { return scholarship_ref };
            i = i + 1;
        };
        abort(E_INVALID_SCHOLARSHIP_OR_UNAUTHORIZED)
    }

    public fun get_scholarship_by_id(scholarships: &vector<Scholarship>, scholarship_id: u64): Scholarship {
        let i = 0;
        while (i < vector::length(scholarships)) {
            let scholarship = vector::borrow(scholarships, i);
            if (scholarship.scholarship_id == scholarship_id) { return *scholarship };
            i = i + 1;
        };
        Scholarship { scholarship_id: 0, name: utf8(b"Invalid Scholarship ID"), donor: @0x0,
            amount_per_applicant: 0, total_applicants: 0, criteria_gpa: 0,
            field_of_study: utf8(b"Invalid Scholarship ID"), end_time: 0, is_open: false }
    }

    fun update_scholarship_status_if_needed(scholarship: &mut Scholarship) {
        if (timestamp::now_seconds() > scholarship.end_time) { scholarship.is_open = false; }
    }

    fun get_donor_address_of_scholarship(scholarship_id: u64): address acquires DonorAddresses, Scholarships {
        let donor_addresses = borrow_global<DonorAddresses>(GLOBAL_DONOR_ADDRESS);
        for (i in 0..vector::length(&donor_addresses.addresses)) {
            let donor_address = vector::borrow(&donor_addresses.addresses, i);
            if (exists<Scholarships>(*donor_address)) {
                let scholarships = borrow_global<Scholarships>(*donor_address);
                for (j in 0..vector::length(&scholarships.scholarships)) {
                    let scholarship = vector::borrow(&scholarships.scholarships, j);
                    if (scholarship.scholarship_id == scholarship_id) { return *donor_address };
                };
            };
        };
        @0x0
    }

    public entry fun apply_for_scholarship(user: &signer, scholarship_id: u64, gpa: u64, field_of_study: String)
    acquires Scholarships, Applications, DonorAddresses, ApplicantAddresses {
        let applicant_address = signer::address_of(user);
        let donor_address = get_donor_address_of_scholarship(scholarship_id);
        assert!(exists<DonorAddresses>(GLOBAL_DONOR_ADDRESS), E_ALREADY_HAS_DONORLIST);
        assert!(exists<Scholarships>(donor_address), E_INVALID_SCHOLARSHIP);
        let scholarships = borrow_global_mut<Scholarships>(donor_address);
        let scholarship = get_scholarship_by_id(&mut scholarships.scholarships, scholarship_id);
        assert!(!(applicant_address == donor_address), E_DONOR_CANNOT_APPLY);
        assert!(gpa <= 10 && gpa >= 0, E_INVALID_GPA_BE_IN_0_TO_10);
        assert!(!exists<Applications>(applicant_address), E_ALREADY_APPLIED);
        if (!exists<Applications>(applicant_address)) {
            move_to<Applications>(user, Applications { applications: vector::empty() });
        };
        assert!(scholarship.is_open, E_INVALID_SCHOLARSHIP_IS_CLOSED);
        assert!(timestamp::now_seconds() <= scholarship.end_time, E_INVALID_SCHOLARSHIP_HAS_TIME_ENDED);
        assert!(gpa >= scholarship.criteria_gpa, E_LOW_GPA_NOT_APPLICABLE);
        assert!(field_of_study == scholarship.field_of_study, E_FIELD_OF_STUDY_NOT_MATCHED);
        let applications = borrow_global_mut<Applications>(applicant_address);
        for (i in 0..vector::length(&applications.applications)) {
            let existing_application = vector::borrow(&applications.applications, i);
            assert!(existing_application.scholarship_id != scholarship_id, E_ALREADY_APPLIED);
        };
        let new_application = Application { applicant: applicant_address, gpa, field_of_study, scholarship_id };
        vector::push_back(&mut applications.applications, new_application);
        add_applicant_address(applicant_address);
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
    public fun view_all_donor_addresses(): vector<address> acquires DonorAddresses {
        borrow_global<DonorAddresses>(GLOBAL_DONOR_ADDRESS).addresses
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
                    vector::push_back(&mut all_scholarships, *vector::borrow(&scholarships.scholarships, j));
                };
            };
        };
        all_scholarships
    }

    #[view]
    public fun view_all_scholarships_applied_by_address(account: address): vector<u64> acquires Applications {
        let applications = borrow_global<Applications>(account);
        let applied_scholarship_ids = vector::empty<u64>();
        let count = vector::length(&applications.applications);
        let i = 0;
        if (!exists<Applications>(account)) { return vector::empty<u64>() };
        while (i < count) {
            vector::push_back(&mut applied_scholarship_ids, vector::borrow(&applications.applications, i).scholarship_id);
            i = i + 1;
        };
        applied_scholarship_id
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
                        vector::push_back(&mut all_applicants, ApplicantData { applicant_address: *applicant_address, gpa: application.gpa });
                    };
                };
            };
        };
        all_applicants
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
                    if (vector::borrow(&applications.applications, j).scholarship_id == scholarship_id) {
                        vector::push_back(&mut all_applicants, *applicant_address);
                    };
                };
            };
        };
        all_applicants
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
                    if (vector::borrow(&applications.applications, j).scholarship_id == scholarship_id) {
                        count = count + 1;
                        break
                    };
                };
            };
        };
        count
    }
}