
#include <chrono>   // for timing
#include <iostream> // std::cout, std::endl
#include <iterator> // std::ostream_iterator
#include <vector>

#include "dense_graph.h"
#include "sparse_graph.h"

#include "data_generator.h"
#include "data_types.h"


template <typename T>
void print_matrix(T* matrix, int m, int n) {
    for (int i = 0; i < m; i++) {
        std::cout << "| ";
        for (int j = 0; j < n; j++) {
            std::cout << matrix[i * m + j] << " ";

        }
        std::cout << "|" << std::endl;
    }
}
/**
 * Runs timing tests on a CUDA graph implementation.
 * Consists of independently constructing the graph and then
 * modifying it to its two-hop neighbourhood.
 */
template < typename DeviceGraph >
void run(DeviceGraph g, csc485b::a2::edge_t const* d_edges, std::size_t m)
{

    cudaDeviceSynchronize();
    auto const build_start = std::chrono::high_resolution_clock::now();

    // this code doesn't work yet!
    int num_blocks = ((int)m / 1024) + 1;
    int threads_per_block = num_blocks > 1 ? 1024 : m;
    std::cout   << "Thread configuration: " 
                << num_blocks 
                << " blocks, " 
                << threads_per_block * num_blocks 
                << " threads" 
                << std::endl;
    csc485b::a2::gpu::build_graph << < num_blocks, threads_per_block >> > (g, d_edges, m);

    cudaDeviceSynchronize();
    auto const reachability_start = std::chrono::high_resolution_clock::now();


    // neither does this!   
    unsigned int tiling_size = std::min(32, (int)g.n);
    unsigned int matrix_size = g.n;
    unsigned int num_block = matrix_size / tiling_size;
    std::cout << "tiling size: " << tiling_size << std::endl;
    std::cout << "matrix size: " << matrix_size << std::endl;

    //csc485b::a2::gpu::two_hop_reachability << < {matrix_size, matrix_size}, { tiling_size, tiling_size } >> > (g);


    cudaDeviceSynchronize();
    auto const end = std::chrono::high_resolution_clock::now();


    std::cout << std::endl
        << "Build time: "
        << std::chrono::duration_cast<std::chrono::microseconds>(reachability_start - build_start).count()
        << " us"
        << std::endl;

    std::cout << "Reachability time: "
        << std::chrono::duration_cast<std::chrono::microseconds>(end - reachability_start).count()
        << " us"
        << std::endl;

}

/**
 * Allocates space for a dense graph and then runs the test code on it.
 */
void run_dense(csc485b::a2::edge_t const* d_edges, std::size_t n, std::size_t m)
{
    using namespace csc485b;

    // allocate device DenseGraph
    a2::node_t* d_matrix;
    cudaMalloc((void**)&d_matrix, sizeof(a2::node_t) * n * n);
    a2::DenseGraph d_dg{ n, d_matrix };

    run(d_dg, d_edges, m);

    // check output?
    std::vector< a2::node_t > host_matrix(d_dg.matrix_size());
    a2::DenseGraph dg{ n, host_matrix.data() };
    cudaMemcpy(dg.adjacencyMatrix, d_dg.adjacencyMatrix, sizeof(a2::node_t) * d_dg.matrix_size(), cudaMemcpyDeviceToHost);
    std::copy(host_matrix.cbegin(), host_matrix.cend(), std::ostream_iterator< a2::node_t >(std::cout, " "));
    std::cout << "\n";
    //print_matrix(dg.adjacencyMatrix, n, n);
    // clean up
    cudaFree(d_matrix);
}

/**
 * Allocates space for a sparse graph and then runs the test code on it.
 */
void run_sparse(csc485b::a2::edge_t const* d_edges, std::size_t n, std::size_t m)
{
    using namespace csc485b;

    // allocate device SparseGraph
    a2::node_t* d_offsets, * d_neighbours;
    cudaMalloc((void**)&d_offsets, sizeof(a2::node_t) * n);
    cudaMalloc((void**)&d_neighbours, sizeof(a2::node_t) * m);
    a2::SparseGraph d_sg{ n, m, d_offsets, d_neighbours };

    run(d_sg, d_edges, m);

    // check output?

    //std::vector< a2::node_t > host_offsets(n);
    //std::vector< a2::node_t > host_neighbours(m);
    //cudaMemcpy(host_offsets, d_sg.neighbours_start_at, sizeof(a2::node_t) * n, cudaMemcpyDeviceToHost);
    //cudaMemcpy(host_neighbours, d_sg.neighbours, sizeof(a2::node_t) * m, cudaMemcpyDeviceToHost);
    //std::copy(host_offsets.cbegin(), host_offsets.cend(), std::ostream_iterator< a2::node_t >(std::cout, " "));
    //std::copy(host_offsets.cbegin(), host_offsets.cend(), std::ostream_iterator< a2::node_t >(std::cout, " "));
    
    // clean up
    cudaFree(d_neighbours);
    cudaFree(d_offsets);
}

int main()
{
    using namespace csc485b;

    // Create input
    std::size_t constexpr n = 128;
    std::size_t constexpr expected_degree = n >> 1;

    a2::edge_list_t const graph = a2::generate_graph(n, n * expected_degree);
    std::size_t const m = graph.size();

    /*// lazily echo out input graph
    std::cout << "Graph: " << std::endl;
    for (auto const& e : graph)
    {
        std::cout << "(" << e.x << "," << e.y << ") ";
    }
    */
    

    // allocate and memcpy input to device
    a2::edge_t* d_edges;
    cudaMalloc((void**)&d_edges, sizeof(a2::edge_t) * m);
    cudaMemcpyAsync(d_edges, graph.data(), sizeof(a2::edge_t) * m, cudaMemcpyHostToDevice);

    // run your code!
    run_dense(d_edges, n, m);
    //run_sparse(d_edges, n, m);

    return EXIT_SUCCESS;
}