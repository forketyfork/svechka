#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

const unsigned int arrayLength = 1 << 24;
const unsigned int bufferSize = arrayLength * sizeof(float);

int main() {

    @autoreleasepool {

        id<MTLDevice> device = MTLCreateSystemDefaultDevice();

        id<MTLLibrary> defaultLibrary = [device newDefaultLibrary];
        if (defaultLibrary == nil)
        {
            NSLog(@"Failed to find the default library.");
            return -1;
        }

        id<MTLFunction> addFunction = [defaultLibrary newFunctionWithName:@"add_arrays"];
        if (addFunction == nil)
        {
            NSLog(@"Failed to find the adder function.");
            return -1;
        }

        NSError* error = nil;
        id<MTLComputePipelineState> addFunctionPSO = [device newComputePipelineStateWithFunction: addFunction error:&error];
        if (addFunctionPSO == nil)
        {
            NSLog(@"Failed to created pipeline state object, error %@.", error);
            return -1;
        }

        id<MTLCommandQueue> commandQueue = [device newCommandQueue];
        if (commandQueue == nil)
        {
            NSLog(@"Failed to find the command queue.");
            return -1;
        }
        
        id<MTLBuffer> bufferA = [device newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
        id<MTLBuffer> bufferB = [device newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
        id<MTLBuffer> bufferResult = [device newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];

        float* dataPtr = bufferA.contents;
    
        for (unsigned long index = 0; index < arrayLength; index++)
        {
            dataPtr[index] = (float)rand()/(float)(RAND_MAX);
        }

        dataPtr = bufferB.contents;
    
        for (unsigned long index = 0; index < arrayLength; index++)
        {
            dataPtr[index] = (float)rand()/(float)(RAND_MAX);
        }

        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        assert(commandBuffer != nil);
    
        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
        assert(computeEncoder != nil);
    
        [computeEncoder setComputePipelineState:addFunctionPSO];
        [computeEncoder setBuffer:bufferA offset:0 atIndex:0];
        [computeEncoder setBuffer:bufferB offset:0 atIndex:1];
        [computeEncoder setBuffer:bufferResult offset:0 atIndex:2];
    
        MTLSize gridSize = MTLSizeMake(arrayLength, 1, 1);
    
        NSUInteger threadGroupSize = addFunctionPSO.maxTotalThreadsPerThreadgroup;
        if (threadGroupSize > arrayLength)
        {
            threadGroupSize = arrayLength;
        }
        MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
    
        [computeEncoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
        
        [computeEncoder endEncoding];
    
        [commandBuffer commit];
    
        [commandBuffer waitUntilCompleted];
    
        float* a = bufferA.contents;
        float* b = bufferB.contents;
        float* result = bufferResult.contents;
    
        for (unsigned long index = 0; index < arrayLength; index++)
        {
            if (result[index] != (a[index] + b[index]))
            {
                printf("Compute ERROR: index=%lu result=%g vs %g=a+b\n",
                       index, result[index], a[index] + b[index]);
                assert(result[index] == (a[index] + b[index]));
            }
        }
        NSLog(@"Compute results as expected");
    }
    return 0;
}
