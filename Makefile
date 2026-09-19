# Lab 07 - MPI collectives
#   make        build all 6 programs
#   make run    run all 6 programs with 4 processes
#   make clean  remove the executables

NP ?= 4

ifeq ($(OS),Windows_NT)
  # MinGW / MSYS2 UCRT64 with MS-MPI
  CC      = gcc
  LDLIBS  = -lmsmpi
  MPIRUN  = mpiexec -n $(NP)
  EXE     = .exe
else
  # Linux / macOS / WSL with Open MPI or MPICH
  CC      = mpicc
  LDLIBS  =
  MPIRUN  = mpirun -np $(NP)
  EXE     =
endif

CFLAGS = -O2 -Wall -std=c99

PROGS = Exercise01/sum_bcast$(EXE) \
        Exercise02/sum_scatter$(EXE) \
        Exercise03/sum_gather$(EXE) \
        Exercise04/sum_reduce$(EXE) \
        Exercise05/sum_allreduce$(EXE) \
        Exercise06/sum_scan$(EXE)

.PHONY: all run clean

all: $(PROGS)

Exercise01/sum_bcast$(EXE): Exercise01/sum_bcast.c
	$(CC) $(CFLAGS) -o $@ $< $(LDLIBS)

Exercise02/sum_scatter$(EXE): Exercise02/sum_scatter.c
	$(CC) $(CFLAGS) -o $@ $< $(LDLIBS)

Exercise03/sum_gather$(EXE): Exercise03/sum_gather.c
	$(CC) $(CFLAGS) -o $@ $< $(LDLIBS)

Exercise04/sum_reduce$(EXE): Exercise04/sum_reduce.c
	$(CC) $(CFLAGS) -o $@ $< $(LDLIBS)

Exercise05/sum_allreduce$(EXE): Exercise05/sum_allreduce.c
	$(CC) $(CFLAGS) -o $@ $< $(LDLIBS)

Exercise06/sum_scan$(EXE): Exercise06/sum_scan.c
	$(CC) $(CFLAGS) -o $@ $< $(LDLIBS)

run: all
	@echo "===== Exercise 1: Bcast + Send/Recv ====="
	$(MPIRUN) ./Exercise01/sum_bcast$(EXE)
	@echo "===== Exercise 2: Scatter ====="
	$(MPIRUN) ./Exercise02/sum_scatter$(EXE)
	@echo "===== Exercise 3: Gather ====="
	$(MPIRUN) ./Exercise03/sum_gather$(EXE)
	@echo "===== Exercise 4: Reduce ====="
	$(MPIRUN) ./Exercise04/sum_reduce$(EXE)
	@echo "===== Exercise 5: Allreduce ====="
	$(MPIRUN) ./Exercise05/sum_allreduce$(EXE)
	@echo "===== Exercise 6: Scan ====="
	$(MPIRUN) ./Exercise06/sum_scan$(EXE)

clean:
	rm -f $(PROGS)
