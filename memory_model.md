This doc explains the memory model of writing cherry program. Some lines are labled "Internally:". They are useful if you want to understand the underlying structure of how the Cherry device works, but not necessary for those who with to just code cherry programs.

## Input and output tensors

Cherry programs can take in up to 6 input tensors and output unlimited output tensors.

Within a cherry program, the set of tensor inputs and the set of tensor outputs must have an intersection equal to the empty set. That is, you can't read and write the same tensor in the same program. Tensors are immutable, so once a tensor is outputted from a previous program, that same tensor can't be overwritten, it can only be used as input to another cherry program. 

Internally: We have 8 cache slots. 4 of them are powerful, their ports have strided read/write. A single cherry program has access to just 3 of these at a time. 2 for input tensors, 1 for output tensor. The other 4 cache slots are weak, they are read only and don't have any strides. These slots are only useful for a cherry programs input tensors. The powerful slots slots have non strided read write access for the DMA. The weak slots have non strided write-only access for the DMA. The DMA bandwidth is so low that we end up striding these over time.

## High Priority vs Low Priority 

High Priority Tensor Inputs
Can have a maximum of 2. Both should be used early in a cherry program
If there's an output tensor already loaded in cache from a previous cherry program, then we'll want to make that one priority.
User can specify another tensor to be priority. If the previous cherry program didn't have an output high priority tensor, then user can specify 2 input tensors to be high priority.
Internally: We are storing these in powerful cache slots so we can do fast strided access. One of them is likely already there before a program starts (output from previous program) and the other one will be loaded in before the program starts.

Low Priority Tensor Inputs
Are in weak cache slots. These slots don't have strides, so these tensors must be loaded over DMA and strided on the host pc side.

High Priority Tensor Outputs
At most 1. This tensor will then be high priority for the next program to use it. If the next program running on the Cherry device doesn't use this tensor, then

## Load and Store Instructions

When a load instruction operates on a high priority tensor input, it's guaranteed to operate in 1.2 cycles on average. These tensors are already loaded into cache before the cherry program starts and the memory slots they are in are powerful enough to stride.

When a load instruction operates on a low priority tensor input, it's possible the instruction can stall. There is no guarantee these tensors are loaded into cache before the cherry program starts. For this reason, it's recommended to only load low priority tensor inputs after some signficant time has passed in the program. This gives the DMA time to transfer the tensor to the cherry device. If your cherry program starts off doing a large tiled matrix multiply, it's likely you won't run into any issues. Large matrix multiplies take much longer than transferring tensors.

When a store instruction stores to the memory location of a high priority tensor output, it's guaranteed to operate in 1.2 cycles on average. The data will go to the cache.

When a store instruction stores to the memory location of a low priority tensor output, it's guaranteed to operate in 1 cycle. The data will enter a buffer. Once reaching the end of the buffer, the data gets DMA'd to the host computer.
