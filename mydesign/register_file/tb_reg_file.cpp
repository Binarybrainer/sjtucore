// status: draft, not complete
#include "Vreg_file.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <memory>
#include <iomanip>
#include <random>
#include <bitset>
#include <cstdint>
#include <iostream>
#include <typeinfo>
// #include <boost/typeindex.hpp>
constexpr int LENGTH = 32;

// Helper function to calculate expected result for validation
#include <array>

void print_test_case(const uint32_t src[], uint32_t address, uint32_t result, bool pass) {
    std::cout << "src = [";
    for (int i = 0; i < LENGTH; i++) {
        std::cout << src[i];
        if (i < LENGTH - 1) std::cout << ", ";
    }
    std::cout << "]";

    std::cout << " | address = " << static_cast<int>(address);
    std::cout << " | result = " << result;
    std::cout << " | " << (pass ? "PASS" : "FAIL") << std::endl;
}

void write_reg_file(std::unique_ptr<Vreg_file>& reg_file, uint32_t address, uint32_t value){
    // TODO: Implement write reg operation
    reg_file -> clk = !(reg_file->clk);
    sim_time ++;
    
    reg_file -> clk = !(reg_file->clk);
    sim_time ++;
}

void read_reg_file(std::unique_ptr<Vreg_file>& reg_file, uint32_t address, uint32_t value){
    reg_file -> address = address;
    sim_time ++;

    return reg_file -> rd_data;
}

void compare_two_array(uint32_t read_back_array[], uint32_t standard_array[]){
    test_pass = true;
    for (i = 0; i < 32; i ++){
        if (read_back_array[i] != standard_array[i]){
            test_pass = false;
            print_different_value();
        }
    }
    return test_pass

}


void check_operation(std::unique_ptr<Vreg_file>& reg_file, VerilatedVcdC* tfp, vluint64_t& sim_time) {
    
    // Test tracking variables
    bool overall_pass = true;
    int tests_passed = 0;
    int total_tests = 0;
    
    
    std::cout << "\nTesting reg_file with random values:" << std::endl;
    std::cout << "------------------------" << std::endl;

    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<uint32_t> distvalue(0, (1<<LENGTH)-1);
    std::uniform_int_distribution<uint32_t> distaddress (0, LENGTH - 1);

    uint32_t write_value[32];

    for (int i = 0; i < 32; i ++){
        write_value[i] = distvalue(gen);
    }

    const int random_test_count = 2;
    total_tests += random_test_count;

    for (int i = 0; i < random_test_count; i++) {
        reg_file -> clk = !(reg_file->clk)

        // TODO: Write all value to standard array, in random order
        for (int i = 0; i < 32; i ++){
            // TODO: Implement random address but have go through all address
            address = randomaddress(gen)
            write_reg_file(reg_file, address, standard_array[i]);
        }
        // TODO: Read back as a duplicate array, in random order
        // TODO: Compare two array

        // TODO: Check for implement sim_time ++
        reg_file->eval();
        if (tfp) tfp->dump(sim_time);
        sim_time++;

        uint32_t expected = expected_reg_file(src, address );

        bool test_pass = (reg_file->data == expected);
        if (test_pass) {
            tests_passed++;
        } else {
            overall_pass = false;
        }

        print_test_case(src, address , reg_file->data, test_pass);
    }

    std::cout << "\n==== Test Summary ====" << std::endl;
    std::cout << "Result: " << (overall_pass ? "Pass" : "Fail") << std::endl;
    std::cout << "Tests: " << std::dec << tests_passed << " of " << total_tests << std::endl;

}

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    
    // Create an instance of our module under test
    std::unique_ptr<Vreg_file> reg_file = std::make_unique<Vreg_file>();
    
    // Initialize VCD trace file
    Verilated::traceEverOn(true);
    std::unique_ptr<VerilatedVcdC> tfp = std::make_unique<VerilatedVcdC>();
    reg_file->trace(tfp.get(), 99);  // Trace 99 levels of hierarchy
    tfp->open("nbit_reg_file_cell_sim.vcd");
    
    // Initialize simulation time
    vluint64_t sim_time = 0;
    
    // Run tests
    check_operation(reg_file, tfp.get(), sim_time);
    
    // Cleanup
    tfp->close();
    reg_file->final();
    
    return 0;
} 