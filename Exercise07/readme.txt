Exercise 7: Summary Comparison
==============================

Problem: sum 1,000,000 integers (1..1,000,000). Expected answer 500,000,500,000.
All 6 programs printed the correct total with 2, 4 and 8 processes.


1. Comparison table
-------------------

| # | Program            | Collectives used           | Memory per process               | Manual sum loop on root?      | Where the final result is available        |
|---|--------------------|----------------------------|----------------------------------|-------------------------------|--------------------------------------------|
| 1 | sum_bcast.c        | Bcast (+ Send/Recv)        | FULL array on every process      | Yes (Recv loop, O(P))         | Root only                                  |
| 2 | sum_scatter.c      | Scatter (+ Send/Recv)      | Full array on root, chunk on rest| Yes (Recv loop, O(P))         | Root only                                  |
| 3 | sum_gather.c       | Scatter, Gather            | Full array on root, chunk on rest| Yes (loop over all_sums[])    | Root only                                  |
| 4 | sum_reduce.c       | Scatter, Reduce            | Full array on root, chunk on rest| No                            | Root only                                  |
| 5 | sum_allreduce.c    | Scatter, Allreduce         | Full array on root, chunk on rest| No                            | ALL processes (same value everywhere)      |
| 6 | sum_scan.c         | Scatter, Scan              | Full array on root, chunk on rest| No                            | DIFFERENT per rank (prefix sum); last rank |
|   |                    |                            |                                  |                               | holds the global total                     |

Notes:
- "Chunk" means N/size elements (250,000 ints with 4 processes).
- In program 1 every rank holds 1,000,000 ints (4 MB). In programs 2-6 only
  root does; the others hold N/size ints.
- In programs 1 and 2 root still receives P-1 messages one by one, so that
  part is a sequential O(P) loop. Gather (3) collects everything in one call
  but root still adds the values itself. Reduce/Allreduce/Scan (4-6) do the
  summing inside MPI using a tree-based O(log P) algorithm.


2. Timings
----------

Setup: Windows 11, 12 logical processors, MinGW-w64 UCRT64 gcc -O2, MS-MPI
10.1 (all processes on one machine, shared memory). Each figure is the median
of 10 runs, in seconds, as printed by the program (MPI_Wtime around
scatter/bcast + local sum + collection).

| Program          | 2 procs | 4 procs | 8 procs |
|------------------|---------|---------|---------|
| 1 sum_bcast      | 0.0018  | 0.0040  | 0.0069  |
| 2 sum_scatter    | 0.0017  | 0.0020  | 0.0026  |
| 3 sum_gather     | 0.0016  | 0.0019  | 0.0027  |
| 4 sum_reduce     | 0.0016  | 0.0028  | 0.0029  |
| 5 sum_allreduce  | 0.0016  | 0.0020  | 0.0028  |
| 6 sum_scan       | 0.0023  | 0.0029  | 0.0037  |

Which is fastest?
- Programs 2-5 (Scatter based) are all fastest and close to each other:
  roughly 0.0016-0.0029 s. The differences between them are a few tenths of a
  millisecond, which is within run-to-run noise on this machine, so I do not
  claim one of them is clearly the winner. At 4 processes Gather and
  Scatter/Allreduce were marginally lowest.
- Program 1 (Bcast) is clearly the slowest once there are 4 or more
  processes (0.0040 s at 4, 0.0069 s at 8) and gets worse as processes are
  added.

Why?
- Bcast sends the ENTIRE 4 MB array to every process, so the data moved grows
  with the number of processes (about P x 4 MB). Every process also has to
  allocate the full array. Scatter sends each process only its own N/P
  elements, so the total data moved stays about 4 MB no matter how many
  processes there are.
- The final collection step moves only a handful of 8-byte values, so the
  choice between Send/Recv, Gather, Reduce and Allreduce is dwarfed by the
  cost of distributing the array. That is why programs 2-5 look almost the
  same here. The tree-based Reduce/Allreduce would matter more with many
  more processes (on a cluster) or larger messages.
- Scan is a little slower because it must compute a prefix result (each rank
  depends on the ranks before it), and its time is measured on the last rank
  (which waits for the whole chain), while the others are measured on root.
- Caveats: the run is only ~2-7 ms, everything is on a single machine, and
  the times include root filling/scattering the array, so the numbers are
  noisy. The trend (Bcast worst and degrading; the Scatter-based versions
  flat and close together) is the reliable part.


3. Thinking question: MPI_Scan vs MPI_Allreduce
-----------------------------------------------

Choose MPI_Scan when each process needs the combined result of only the
processes BEFORE it (and itself), not the global total. Allreduce gives
everyone the same value; Scan gives each rank its own running total, which
acts as an offset.

Concrete example: variable-sized output. Each of P processes filters its part
of a big dataset and keeps a different number of records (rank 0 keeps 120,
rank 1 keeps 80, rank 2 keeps 200, ...). To write all results into one global
array (or file) in order, rank r needs to know where its records start, i.e.
the number of records kept by ranks 0..r-1. Scan with MPI_SUM on the kept
counts gives prefix_sum; the starting offset is prefix_sum - my_count (exactly
the sum_before_me from Exercise 6). Each rank can then write to its own
non-overlapping slot with no further communication. Allreduce could only tell
every rank the grand total (e.g. the size of the final array), not where its
own slice begins.

Other uses: assigning global IDs/indices, cumulative distributions, and
splitting work so each rank gets a load-balanced range.
