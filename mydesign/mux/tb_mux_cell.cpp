#include "Vmux_cell.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <memory>
#include <iomanip>
#include <random>
#include <bitset>
#include <cstdint>
// status: trying 
#include <iostream>
#include <typeinfo>
// #include <boost/typeindex.hpp>
constexpr int LENGTH = 32;

// Helper function to calculate expected result for validation
uint64_t expected_mux(const uint8_t src[], uint8_t sel) {
    return src[sel];
}

#include <array>

void print_test_case(const uint8_t src[], uint8_t sel, bool result, bool pass) {
    std::cout << "src = [";
    for (int i = 0; i < LENGTH; i++) {
        std::cout << (src[i] ? "1" : "0");
        if (i < LENGTH - 1) std::cout << ", ";
    }
    std::cout << "]";

    std::cout << " | sel = " << static_cast<int>(sel);
    std::cout << " | result = " << (result ? "1" : "0");
    std::cout << " | " << (pass ? "PASS" : "FAIL") << std::endl;
}



void check_operation(std::unique_ptr<Vmux_cell>& mux, VerilatedVcdC* tfp, vluint64_t& sim_time) {
    
    // Test tracking variables
    bool overall_pass = true;
    int tests_passed = 0;
    int total_tests = 0;
    
    
    std::cout << "\nTesting mux with random values:" << std::endl;
    std::cout << "------------------------" << std::endl;

    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<uint8_t> dist01(0, 1);
    std::uniform_int_distribution<uint8_t> distSel(0, LENGTH - 1);

    const int random_test_count = 200;
    total_tests += random_test_count;

    for (int i = 0; i < random_test_count; i++) {
        uint8_t src[LENGTH];
        for (uint8_t j = 0; j < LENGTH; j++) {
            src[j] = dist01(gen);
            mux->src[j] = src[j];
        }
        uint8_t sel = distSel(gen);
        mux->sel = sel;

        mux->eval();
        if (tfp) tfp->dump(sim_time);
        sim_time++;

        uint8_t expected = expected_mux(src, sel);

        bool test_pass = (mux->data == expected);
        if (test_pass) {
            tests_passed++;
        } else {
            overall_pass = false;
        }

        print_test_case(src, sel, mux->data, test_pass);
    }

    std::cout << "\n==== Test Summary ====" << std::endl;
    std::cout << "Result: " << (overall_pass ? "Pass" : "Fail") << std::endl;
    std::cout << "Tests: " << std::dec << tests_passed << " of " << total_tests << std::endl;

}

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    
    // Create an instance of our module under test
    std::unique_ptr<Vmux_cell> mux = std::make_unique<Vmux_cell>();
    
    // Initialize VCD trace file
    Verilated::traceEverOn(true);
    std::unique_ptr<VerilatedVcdC> tfp = std::make_unique<VerilatedVcdC>();
    mux->trace(tfp.get(), 99);  // Trace 99 levels of hierarchy
    tfp->open("mux_cell_sim.vcd");
    
    // Initialize simulation time
    vluint64_t sim_time = 0;
    
    // Run tests
    check_operation(mux, tfp.get(), sim_time);
    
    // Cleanup
    tfp->close();
    mux->final();
    
    return 0;
} 