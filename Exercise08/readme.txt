Exercise 8: Compile and Run
===========================

The Makefile is in the repository root (next to Readme.md).

Programs (one per folder):
  Exercise01/sum_bcast.c       Bcast + Send/Recv
  Exercise02/sum_scatter.c     Scatter + Send/Recv
  Exercise03/sum_gather.c      Scatter + Gather
  Exercise04/sum_reduce.c      Scatter + Reduce
  Exercise05/sum_allreduce.c   Scatter + Allreduce
  Exercise06/sum_scan.c        Scatter + Scan

Usage:
  make          build all 6 programs
  make run      build (if needed) and run all 6 with 4 processes
  make clean    remove the executables
  make run NP=8 run all 6 with a different number of processes

The Makefile detects the platform:
  Linux / macOS / WSL :  mpicc + mpirun -np N
  Windows (MSYS2 UCRT64 + MS-MPI): gcc ... -lmsmpi + mpiexec -n N
      (use mingw32-make instead of make)

Tested on Windows with MSYS2 UCRT64 gcc + MS-MPI 10.1:
  mingw32-make run
All 6 programs print Total sum = 500000500000, Correct? = YES.
