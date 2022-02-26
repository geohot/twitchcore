from enum import Enum
from dataclasses import dataclass

HIGH_PRIO_SLOTS = 4
LOW_PRIO_INPUT_SLOTS = 4

class SlotType(Enum):
    HIGH_PRIORITY_READ_AND_WRITE = 0
    LOW_PRIORITY_READ = 1
    LOW_PRIORITY_WRITE = 2

@dataclass
class Slot():
    index: int # index within it's type. So for all types, start index at 0
    slot_type: SlotType

class MemoryAllocator():
    def __init__(self):
        self.cur_prog_slots = []
        self.cur_prog_id = 0


    def start_next_prog_context(self):
        self.prev_prog_slots = self.cur_prog_slots
        self.cur_prog_slots = []
        self.cur_prog_used_low_prio_input_count = -1
        self.cur_prog_used_low_prio_output_count = -1
        self.cur_prog_id += 1
        self.has_called_high_prio_output = False

    def _malloc_empty_high_prio_slot(self):
        possible_slots = [Slot(i, SlotType.HIGH_PRIORITY_READ_AND_WRITE) for i in range(HIGH_PRIO_SLOTS)]
        reserved_slots = self.prev_prog_slots + self.cur_prog_slots
        for slot in possible_slots:
            if slot not in reserved_slots:
                self.cur_prog_slots.append(slot)
                return slot
        raise AssertionError("Bad, no slot free, sorry.")
    
    def _malloc_empty_high_prio_slot_cur_prog(self):
        possible_slots = [Slot(i, SlotType.HIGH_PRIORITY_READ_AND_WRITE) for i in range(HIGH_PRIO_SLOTS)]
        reserved_slots = self.cur_prog_slots
        for slot in possible_slots:
            if slot not in reserved_slots:
                self.cur_prog_slots.append(slot)
                return slot
        raise AssertionError("Bad, no slot free, sorry.")

    def malloc_high_prio_input(self, slot_index=None):
        assert not self.has_called_high_prio_output
        # only works if either or
        # 1. the tensor is output of the last program.
        # 2. Use an empty spot from last program, should be atelast 1

        # For 1, set slot index param
        # For 2, leave slot index param None

        if slot_index:
            # 1. Assert the tensor (slot index) is output or input of the last program
            new_slot = Slot(index=slot_index, slot_type=SlotType.HIGH_PRIORITY_READ_AND_WRITE)
            assert any([slot == new_slot for slot in self.prev_prog_slots])
            self.cur_prog_slots.append(new_slot)
            return new_slot
        else:
            # 2. Assert the last program left a high prio slot free.
            # There's 4 high prio slots, and the last program could have used at most 3. So we can run this op at least once
            return self._malloc_empty_high_prio_slot()
    
    def malloc_high_prio_output(self):
        self.has_called_high_prio_output = True
        # take any slot unused for current prog. Then assert we aren't using more than 3
        new = self._malloc_empty_high_prio_slot_cur_prog()
        total_high_prio_used = sum([slot.slot_type == SlotType.HIGH_PRIORITY_READ_AND_WRITE for slot in self.cur_prog_slots])
        assert total_high_prio_used <= 3
        return new

    def malloc_low_prio_input(self):
        self.cur_prog_used_low_prio_input_count += 1
        assert self.cur_prog_used_low_prio_input_count < LOW_PRIO_INPUT_SLOTS
        self.cur_prog_slots.append(Slot(index=self.cur_prog_used_low_prio_input_count, slot_type=SlotType.LOW_PRIORITY_READ))
        return self.cur_prog_used_low_prio_input_count

    def malloc_low_prio_output(self):
        self.cur_prog_used_low_prio_output_count += 1
        self.cur_prog_slots.append(Slot(index=self.cur_prog_used_low_prio_output_count, slot_type=SlotType.LOW_PRIORITY_WRITE))
        return self.cur_prog_used_low_prio_output_count

# test
if __name__ == "__main__":
    allocator = MemoryAllocator()
    allocator.start_next_prog_context()
    input_slot = allocator.malloc_high_prio_input()
    input_slot_2 = allocator.malloc_high_prio_input()
    output_slot = allocator.malloc_high_prio_output()
    assert input_slot.index == 0 and input_slot.slot_type == SlotType.HIGH_PRIORITY_READ_AND_WRITE
    assert input_slot_2.index == 1 and input_slot_2.slot_type == SlotType.HIGH_PRIORITY_READ_AND_WRITE
    assert output_slot.index == 2 and output_slot.slot_type == SlotType.HIGH_PRIORITY_READ_AND_WRITE

    allocator.start_next_prog_context()
    input_slot = allocator.malloc_high_prio_input()
    input_slot_2 = allocator.malloc_high_prio_input(slot_index=output_slot.index)
    output_slot = allocator.malloc_high_prio_output()
    assert input_slot.index == 3 and input_slot.slot_type == SlotType.HIGH_PRIORITY_READ_AND_WRITE
    assert input_slot_2.index == 2 and input_slot_2.slot_type == SlotType.HIGH_PRIORITY_READ_AND_WRITE
    assert output_slot.index == 0 and output_slot.slot_type == SlotType.HIGH_PRIORITY_READ_AND_WRITE
    for i in range (4):
        assert i == allocator.malloc_low_prio_input()
    for i in range (10):
        assert i == allocator.malloc_low_prio_output()
    