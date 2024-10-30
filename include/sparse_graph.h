#include <cstddef>  // std::size_t type

#include "cuda_common.h"
#include "data_types.h"

namespace csc485b {
    namespace a2 {

        /**
         * A SparseGraph is optimised for a graph in which the number of edges
         * is close to cn, for a small constanct c. It is represented in CSR format.
         */
        struct SparseGraph
        {
            std::size_t n; /**< Number of nodes in the graph. */
            std::size_t m; /**< Number of edges in the graph. */
            node_t* neighbours_start_at; /** Pointer to an n=|V| offset array */
            node_t* neighbours; /** Pointer to an m=|E| array of edge destinations */
        };


        namespace gpu {

            /**
             * Constructs a SparseGraph from an input edge list of m edges.
             *
             * @pre The pointers in SparseGraph g have already been allocated.
             */
            __global__
                void build_graph(SparseGraph g, edge_t const* edge_list, std::size_t m)
            {
                /*
                int warp_size = 32;
                /** STEP 1: Build the "neighbours_start_at" list ** /
                // get thread id
                const int thread_id = blockIdx.x * blockDim.x + threadIdx.x;
                // get warp-lane id (0-31)
                const int warp_lane = threadIdx.x % warp_size;
                // extract node ids from related edge
                const int node_a = edge_list[thread_id].x;
                const int node_b = edge_list[thread_id].y;
                // get info about threads in warp that share "from" node
                unsigned int share_mask = __match_any_sync(__activemask(), node_a); // Get mask of share group TODO Figure out how to run this or find alternative
                const int count = __popc(share_mask); // Count share group
                // determine whether thread has smallest ID in share group (For solitary ops); hereon "Control thread"
                int lowest_sharing_thread = 0;// __reduce_min_sync(share_mask, thread_id) == thread_id; // TODO NEED TO SWITCH TO __shfl_xor_sync()
                if (lowest_sharing_thread) {
                    atomicAdd(&g.neighbours_start_at[node_a], count); // Control thread securely increments the n_s_a entry
                }
                */
                /** STEP 2: Tile warps for sequential building of "neighbours" list **/
                /*
                __syncthreads();
                // initialize shared memory variable int* neighbours_build_progress // This will track the number of values add for each node represented by index
                __shared__ int neighbours_build_progress[g.n];
                const int warp_id = (int)thread_id / warp_size;
                // count distance from front within warp (i.e. threads in warp with same node_a will have offsets 0,1,2,3...)
                in_warp_node_offset = ...;// TODOcount how many nodes in share_mask in front of self
                // Begin Tiling
                // for (warp in thread block) { // TODO Iterate through this. Will this work if two thread blocks of different sizes?
                    // if warp = warp id { // i.e. current warp
                        // in_warp_node_offset += neighbours_build_progress[node_a];
                        // __syncwarp(); // Rigid order of read/update; I believe this to be faster than atomicAdd, as entire warp is capable of performing read/write concurrently
                        // g.neighbours[g.neighbours_start_at[node_a] + in_warp_node_offset] = node_b
                        // if (lowest_sharing_thread) {
                            // neighbours_build_progress[node_a] += count // Control thread updates the build progress
                        // }
                    // __syncthreads(); // Step the warps through
                //*/
                return;
            }

            /**
              * Repopulates the adjacency lists as a new graph that represents
              * the two-hop neighbourhood of input graph g
              */
            __global__
                void two_hop_reachability(SparseGraph g)
            {
                // IMPLEMENT ME!
                // algorithm unknown
                return;
            }

        } // namespace gpu
    } // namespace a2
} // namespace csc485b