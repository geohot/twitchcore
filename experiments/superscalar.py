# This script has the superscalar algorithm we will implement in hardware
# I wonder if it makes sense to have two possible superscalar widths. I can't think of any real use case but a single bit could allow user to swap kernels between superscalar width 4 and width 16

# ===== Setup python =====

SUPERSCALAR_WIDTH = 12 # If you have latency induced stalls, make this number bigger.
LOOP_ITER = 96
SAD_FACTOR = (LOOP_ITER % SUPERSCALAR_WIDTH) / LOOP_ITER # larger this number, worse off you are. Can be fixed by picking a large loop. Or smaller superscalar width. or loop iteration power of 2. In real life shouldn't be a problem unless you are working with tiny matrices. Large superscalar width (deriving from large latency) makes it hard for us to support small tensors
program = ["load", "load", "matmul", "store"]
memory_q = ["_"] * 1000
processing_q = ["_"] * 1000

def get_type(instr):
    return "memory" if instr == "load" or instr == "store" else "processing"

latency = {
    "memory": 4,
    "processing": 7
}

prevInstrType = "memory"
next_spot_in_queue = {
    "memory": 0,
    "processing": 0
}
queue_position_when_done_for_queue_type = {
    "memory": 0,
    "processing": 0
}

def superscalar_insert(instr, q, insert_spot, copy_count):
    for i in range(copy_count):
        q[insert_spot + i] = instr

# ===== Superscalar algorithm that takes maybe 20 LUTs =====

for i in range(0, LOOP_ITER, SUPERSCALAR_WIDTH):
    for instr in program:
        # In real life insert_spot is relative to next open spot in queue (not an absolute queue address) or something
        insert_spot = max(queue_position_when_done_for_queue_type[prevInstrType], next_spot_in_queue[get_type(instr)])
        superscalar_insert(
            instr=instr,
            q=memory_q if get_type(instr) == "memory" else processing_q,
            insert_spot=insert_spot,
            copy_count=SUPERSCALAR_WIDTH if LOOP_ITER - i > SUPERSCALAR_WIDTH else LOOP_ITER - i # same copy count function from the hardware
        )
        next_spot_in_queue[get_type(instr)] = insert_spot+SUPERSCALAR_WIDTH
        queue_position_when_done_for_queue_type[get_type(instr)] = insert_spot + latency[get_type(instr)]
        prevInstrType = get_type(instr)
    instructions_used = max(next_spot_in_queue.values())


# ===== Show Stats =====

def bold(s):
    return "\033[1m" + s + "\033[0m"

print(bold(f"\n\n{'===================================':^60}\n{'====== S U P E R S C A L A R ======':^60}\n{'===================================':^60}\n"))
print()
print(bold(f"{'====== Visualization ======':^60}\n"))
print(f"{'':<15}   {bold('Memory'):<22}   {bold('Processing'):<23}")
i = 0
for a, b in zip(memory_q[:instructions_used],processing_q[:instructions_used]):
    print(f"{i:<15}   {a:<22}   {b:<23}")
    i += 1

memory_q_used = sum([0 if i == '_' else 1 for i in memory_q[:instructions_used]])
processing_q_used = sum([0 if i == '_' else 1 for i in processing_q[:instructions_used]])
print()
print(bold(f"{'====== Statistics ======':^60}\n"))
print(f"{bold('Memory utilization:'):<35} {memory_q_used/instructions_used:>25.2%}")
print(f"{bold('Processing utilization:'):<35} {processing_q_used/instructions_used:>25.2%}")
print(f"{bold('Instructions per Cycle:'):<35} {(memory_q_used + processing_q_used) / instructions_used:>25.2f} (technically more with loop instructions)")
print(f"{bold('Expected workload success:'):<35} {SAD_FACTOR:>25.2f}")