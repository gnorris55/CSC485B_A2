
#include <cstddef>  // std::size_t type
#include <iostream> // std::cout, std::endl
#include <vector>

#include "algorithm_choices.h"
#include "data_generator.h"
#include "data_types.h"
#include "cuda_common.h"

int main()
{
    std::size_t const n = 32*32;
    std::size_t const switch_at = 3 * (n >> 2);

    auto data = csc485b::a1::generate_uniform< element_t >(n);
    csc485b::a1::cpu::run_cpu_baseline(data, switch_at, n);
    csc485b::a1::gpu::run_gpu_soln(data, switch_at, n);

    std::cout << "hello world!" << std::endl;
    return EXIT_SUCCESS;
}