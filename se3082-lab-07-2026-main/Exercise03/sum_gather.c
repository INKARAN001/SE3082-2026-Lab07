#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

#define N 1000000

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    int chunk_size = N / size;

    /* Only root allocates the full array; everyone allocates a chunk. */
    int *array = NULL;
    int *local_chunk = (int *)malloc(chunk_size * sizeof(int));

    /* Root fills the array with values 1 to N */
    if (rank == 0) {
        array = (int *)malloc(N * sizeof(int));
        for (int i = 0; i < N; i++)
            array[i] = i + 1;
        printf("Root filled array with values 1 to %d\n", N);
    }

    double start = MPI_Wtime();

    MPI_Scatter(array, chunk_size, MPI_INT,
                local_chunk, chunk_size, MPI_INT,
                0, MPI_COMM_WORLD);

    int start_idx = rank * chunk_size;
    int end_idx = start_idx + chunk_size;

    long long local_sum = 0;
    for (int i = 0; i < chunk_size; i++)
        local_sum += local_chunk[i];

    printf("  Rank %d: summed indices [%d, %d) => local_sum = %lld\n",
           rank, start_idx, end_idx, local_sum);

    /*
     * On root, allocate room for one long long per process.
     * Non-root processes pass NULL: recvbuf is only used on root.
     */
    long long *all_sums = NULL;
    if (rank == 0)
        all_sums = (long long *)malloc(size * sizeof(long long));

    /*
     * GATHER: every process sends 1 long long; root receives them in
     * rank order, so all_sums[r] holds rank r's local_sum.
     * recvcount is the count received FROM EACH process (1), not the total.
     */
    MPI_Gather(&local_sum, 1, MPI_LONG_LONG,
               all_sums, 1, MPI_LONG_LONG,
               0, MPI_COMM_WORLD);

    if (rank == 0) {
        /* Gather does no computation: root still adds the values itself. */
        long long total_sum = 0;
        for (int r = 0; r < size; r++)
            total_sum += all_sums[r];

        double elapsed = MPI_Wtime() - start;
        long long expected = (long long)N * (N + 1) / 2;
        printf("\n[Gather] Total sum   = %lld\n", total_sum);
        printf("[Gather] Expected    = %lld\n", expected);
        printf("[Gather] Correct?    = %s\n", total_sum == expected ? "YES" : "NO");
        printf("[Gather] Time        = %.4f sec\n", elapsed);

        free(all_sums);
        free(array);
    }

    free(local_chunk);
    MPI_Finalize();
    return 0;
}
